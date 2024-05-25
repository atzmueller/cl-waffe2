
(in-package :cl-waffe2/vm.test)

(defun lazy-axis-net-1 ()
  (let ((out (build
	      (!add
	       (make-input `(A B) :X)
	       (make-tensor
		(make-lazyaxis `(+ A B))))
	      :inputs `(:X))))
    (progn
      (= 7.0 (vref (forward out (ax+b `(3 4) 0 0)) 0)))))

(defun lazy-axis-net-adjust-later ()
  (let ((out (build
	      (!add
	       (make-input `(A B) :X)
	       (make-tensor
		(make-lazyaxis `(+ A B))))
	      :inputs `(:X))))
    (and
     (= 7.0 (vref (forward out (ax+b `(3 4) 0 0)) 0))
     (= 8.0 (vref (forward out (ax+b `(4 4) 0 0)) 0)))))

;; ScalarTensors with LazyAxis works well?
(deftest lazy-axis-scalar-test
  (ok (lazy-axis-net-1))
  (ok (lazy-axis-net-adjust-later)))

(defun conv2d-forward-test ()
  (call (Conv2D 3 6 `(5 5)) (make-input `(N 3 25 25) nil)))

(defun avg-pool2d-forward-test ()
  (call (AvgPool2d `(5 5)) (make-input `(N 3 25 25) nil)))

(defun max-pool2d-forward-test ()
  (call (MaxPool2d `(5 5)) (make-input `(N 3 25 25) nil)))


;; Testing just a node construction
(deftest dynamic-cnn-node-construction-test
  (ok (conv2d-forward-test))
  (ok (avg-pool2d-forward-test))
  (ok (max-pool2d-forward-test)))

(defsequence LazyCNN (&key
		      (out-channels1 4)
		      (out-channels2 16))
	     (Conv2D 1 out-channels1 `(3 3))
	     (asnode #'!relu)     
	     (MaxPool2D    `(2 2))
	     (Conv2D out-channels1 out-channels2 `(5 5))
	     (asnode #'!relu)
	     (MaxPool2D `(2 2))
	     (asnode #'!reshape t (* 16 4 4))
	     (LinearLayer (* 16 4 4) 10))

(defun cnn-build-test-cputensor ()
  (build (call (LazyCNN) (make-input `(N 1 28 28) :X)) :inputs `(:X)))

(deftest dynamic-shape-build
  (ok (cnn-build-test-cputensor)))

(defun cnn-train-test-cpu-fw ()
  (let ((model (cnn-build-test-cputensor)))
    (forward model (randn `(100 1 28 28)))
    ;;(backward model)
    (forward model (randn `(10 1 28 28)))
    ;;(backward model)
    (forward model (randn `(121 1 28 28)))
    ;;(backward model)
    t))

(defun cnn-train-test-cpu-fwbw ()
  (let ((model (cnn-build-test-cputensor)))
    (forward model (randn `(100 1 28 28)))
    (backward model)
    (forward model (randn `(10 1 28 28)))
    (backward model)
    (forward model (randn `(121 1 28 28)))
    (backward model)
    t))

;; Including JITCPUTensor Test...
(deftest dynamic-shaped-cnn-build-test
  (ok (cnn-train-test-cpu-fw)))

(deftest dynamic-shaped-cnn-build-test-diff
  (ok (cnn-train-test-cpu-fwbw)))

(defun make-test-tensor ()
  (!reshape (make-input `(N C H W) :X) (~ N C H W -> (* N C H) W)))

(defun lazy-feature-test ()
  (let ((model
	  (build (lazy #'sin (make-test-tensor)) :inputs `(:X))))
    (let ((a (forward model (ax+b `(3 3 3 3) 0 1))))
      (every #'(lambda (i) (= i (sin 1))) (tensor-vec a)))))

(deftest dynamic-lazy-tset
  (ok (lazy-feature-test)))

(defun do-compiled-dynamic-test ()
  (let ((model
	  (build (!expt (make-test-tensor) 2) :inputs `(:X))))
    (let ((a (forward model (ax+b `(3 3 3 3) 0 2))))
      (every #'(lambda (i) (= i (expt 2 2))) (tensor-vec a)))))

(deftest do-compiled-dynamic-test
  (ok (do-compiled-dynamic-test)))

;; [TO ADD]: where
;; (funcall (where A[i j] B[i j] -> C[i j] where i = (* 2 x))
;;  	    (randn `(3 3))
;;	    (randn `(3 3)))


(defun lazyaxis-and-symbol-comparison ()
  (build (softmax-cross-entropy
	  (!reshape (call (Conv2D 3 6 `(5 5)) (make-input `(N 3 25 25) :X)) (~ N C H W -> N (* C H W)))
	  (make-input `(N 2646) :X))))

(deftest lazyaxis-and-symbol-comparison
  (ok (lazyaxis-and-symbol-comparison)))
  
