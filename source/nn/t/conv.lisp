
(in-package :cl-waffe2/nn.test)


(defun conv-2d-forward-test ()
  (let ((model (Conv2D 3 6 `(2 2))))
    (equal `(3 6 9 9) (shape (proceed (call model (randn `(3 3 10 10))))))))

(defun conv-2d-fw-bw-test ()
  (let ((model (Conv2D 3 6 `(2 2))))
    (let ((compiled-model
	    (build
	     (!mean (call model (ax+b `(3 3 10 10) 0.001 0))))))
      (forward compiled-model)
      (backward compiled-model)
      (let ((f t))
	(dotimes (i 6)
	  (dotimes (k 3)
	    (let ((out (proceed (->contiguous (!view (grad (weight-of model)) i k)))))
	      ;; [window0]
	      ;; (ch1.grad ..
	      ;;  .. ..)
	      ;;  (ch1.grad ..
	      ;; .. ..)
	      ;; ...
	      
	      (when (and f (every #'(lambda (x) (= x (vref out 0))) (tensor-vec out)))
		(setq f nil)))))
	f))))

(defun conv-2d-fw-bw-test-1 ()
  (let ((model (Conv2D 3 6 `(2 2) :bias nil)))
    (let ((compiled-model
	    (build (call model (randn `(3 3 10 10))))))
      (forward compiled-model)
      (backward compiled-model)
      (and
       (grad (weight-of model))
       (null (bias-of   model))))))

(defun unfold-test-forward ()
  (let* ((img (ax+b `(2 2 2 2) 1 0))
	 (out (cl-waffe2/nn::unfold img `(1 1) `(2 2) `(1 1) `(0 0))))
    (every #'=
     #(0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0)
     (change-facet (proceed out) :direction 'simple-array))))

(defun unfold-test-backward ()
  (let* ((img (parameter (ax+b `(2 2 2 2) 1 0)))
	 (out (cl-waffe2/nn::unfold img `(1 1) `(2 2) `(1 1) `(0 0))))
    (proceed-backward
     (!sum
      (!mul out (ax+b `(2 8) 1 0))))
    (every #'=
	   #(0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0)
	   (tensor-vec (grad img)))))

(deftest conv2d-fw-bw-test
  (testing "Testing Conv2D Function"
    (ok (conv-2d-forward-test))
    (ok (conv-2d-fw-bw-test))
    (ok (conv-2d-fw-bw-test-1))))

(deftest im2col-test
  (testing "Testing im2col"
    (ok (unfold-test-forward))
    (ok (unfold-test-backward))))


;; MaxPoolTest
;; AvgPoolTest

;; Building CNN and proceed it.

;; AvgPool: 0.0208

(defun non-zerop (x) (not (zerop x)))

(defun 2d-pool-test (avg)
  (let* ((model (if avg
		    (AvgPool2D `(4 4))
		    (MaxPool2D `(4 4))))
	 (prev (parameter (randn `(1 3 16 16))))
	 (out  (build (!mean (call model prev))))
	 (f t))
    (forward  out)
    (backward out)
    (dotimes (i 1)
      (dotimes (k 3)
	(let ((window (proceed
		       (->contiguous
			(!view (grad prev) i k)))))
	  (if avg
	      (setq f (and f (every #'(lambda (x) (= 0.0013020834 x)) (tensor-vec window))))
	      (setq f (and f
			   (let ((grad-n (count-if #'non-zerop (tensor-vec window)))
				 (grad-item (find-if #'non-zerop (tensor-vec window))))
			     (and
			      (= grad-n 16)
			      (= grad-item 0.020833334)))))))))
    
    f))

(deftest 2d-pool-test
  (testing "Testing 2DPool"
    (ok (2d-pool-test nil))
    (ok (2d-pool-test t))
    (ok (2d-pool-test t))
    (ok (2d-pool-test nil))))

