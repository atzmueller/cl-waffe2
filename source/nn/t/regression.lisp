
(in-package :cl-waffe2/nn.test)

;;
;; Comments written in JP/EN is mixed, i'm sorry.
;;


;; Known Issue: Computing the backwards of sequence of LinearLayer,
;; Some weights of layers (esp, 2th~3th), will become zero.
;; The assumption is that acceptor.lisp contributes to this problems.

(defsequence LinearLayer-Sequence (in-features hidden-size out-features)
	     "Testing model for LinearLayer's backwards"
	     (LinearLayer in-features out-features)
	     (asnode #'!relu)
	     (LinearLayer out-features hidden-size) ;; 2th
	     (asnode #'!relu)
	     (LinearLayer hidden-size out-features) ;; 3th
	     (asnode #'!relu)
	     (asnode #'!mean))


(defsequence LinearLayer-Sequence1 (in-features hidden-size out-features)
	     "Testing model for LinearLayer's backwards"
	     (LinearLayer in-features out-features)
	     (asnode #'!relu)
	     (LinearLayer out-features hidden-size) ;; 2th
	     (asnode #'!relu)
	     (LinearLayer hidden-size out-features) ;; 3th
	     )

(defun not-zero-p (tensor)
  (some #'(lambda (x) (not (= x 0))) (tensor-vec (grad tensor))))

;; Chain Rule is Really Working?

(defun matmul-chain-test ()
  (let ((a (parameter (randn `(100 100))))
	(b (parameter (randn `(100 100))))
	(c (parameter (randn `(100 100)))))
    (proceed-backward (!sum (!matmul a (!matmul b c))))
    (and (not-zero-p a)
	 (not-zero-p b)
	 (not-zero-p c))))

(defun matmul-chain-test-smol ()
  (let ((a (parameter (ax+b `(3 3) 0 2)))
	(b (parameter (ax+b `(3 5) 0 3)))
	(c (parameter (ax+b `(5 3) 0 4))))
    (proceed-backward (!sum (!matmul a (!matmul b c))))
    (and (not-zero-p a)
	 (not-zero-p b)
	 (not-zero-p c))))

(defun matmul-chain-test1 ()
  (let ((a (parameter (randn `(100 100))))
	(b (parameter (randn `(100 100))))
	(c (parameter (randn `(100 100)))))
    (proceed-backward (!matmul a (!relu (!matmul b c))))
    (and
     (not-zero-p a)
     (not-zero-p b)
     (not-zero-p c))))

(defun matmul-bias-test ()
  (let ((a (parameter (randn `(100 100))))
	(b (parameter (randn `(100 100))))
	(c (parameter (randn `(100)))))
    (proceed-backward (!sum (cl-waffe2/nn::step-linear a b c)))
    (and
     (not-zero-p a)
     (not-zero-p b)
     (every #'(lambda (x) (= x 1.0)) (tensor-vec (grad c))))))

;; Linear(ReLU(Linear(x)))
(defun linear-chain-test ()
  (let ((a1 (parameter (randn `(100 100))))
	(b1 (parameter (randn `(100 100))))
	(c1 (parameter (randn `(100))))
	(a2 (parameter (randn `(100 100))))
	(c2 (parameter (randn `(100)))))
    (proceed-backward (!mean
		       (cl-waffe2/nn::step-linear
			a2
			(!relu (cl-waffe2/nn::step-linear a1 b1 c1))
			c2)))
    (and
     (not-zero-p a1)
     (not-zero-p b1)
     (not-zero-p c1)
     (not-zero-p a2)
     (every #'(lambda (x) (= x 1e-4)) (tensor-vec (grad c2))))))


;; Doing same things with build
(defun linear-chain-test-build ()
  (let ((a1 (parameter (randn `(100 100))))
	(b1 (parameter (randn `(100 100))))
	(c1 (parameter (randn `(100))))
	(a2 (parameter (randn `(100 100))))
	(c2 (parameter (randn `(100)))))
    (let ((model (build (!mean
			 (cl-waffe2/nn::step-linear
			  a2
			  (!relu (cl-waffe2/nn::step-linear a1 b1 c1))
			  c2)))))
      (forward model)
      (backward model)
      (and
       (not-zero-p a1)
       (not-zero-p b1)
       (not-zero-p c1)
       (not-zero-p a2)
       (every #'(lambda (x) (= x 1e-4)) (tensor-vec (grad c2)))))))


(deftest chain-rule-test-matmul
  (testing "Testing the autodiff with various case of using matmul."
    (ok (matmul-chain-test))
    (ok (matmul-chain-test1))
    (ok (matmul-bias-test))
    (ok (linear-chain-test))
    (ok (linear-chain-test-build))))

;; ===========================================================================================
;; Bug: matmul(not(square).T, any_matrix) -> Segfault (Now it's FIXED)
;;
;;
;;
;; Same operation with linear-composite-test-single-layer
;; Controlled Experiment:

;; The Problem is that:
;; No matter how many times I invoke this function, there's no side effects.
(defun linear-non-composite-test-single-layer ()
  (let ((model-weight (parameter (xavier-uniform `(100 100))))
	(model-bias   (parameter (uniform-random `(100) -0.1 0.1))))
    (let ((out (build (!mean (cl-waffe2/nn::step-linear (randn `(10 100))
							model-weight
							model-bias)))))
      (forward out)
      (backward out)
      (and
       (not-zero-p model-weight)
       (every #'(lambda (x) (= x 0.001)) (tensor-vec (grad model-bias)))))))

;; Setting construct-backward? = nil -> it is working.
;; => Therefore, system-lazy-save-for-backward do not contribute to this problem.
(defun linear-non-composite-test-single-layer-no-bw ()
  (let ((model-weight (parameter (xavier-uniform `(100 100))))
	(model-bias   (parameter (uniform-random `(100) -0.1 0.1))))
    (let ((out (build (!mean (cl-waffe2/nn::step-linear (randn `(10 100))
							model-weight
							model-bias))
		      :construct-backward? nil)))
      (forward out))))


;; Multiple call <- No Side Effects???
(deftest linear-simple-layer
  (testing "Testing the build function using LinearLayer"
    (ok (linear-non-composite-test-single-layer))
    (ok (linear-non-composite-test-single-layer))
    (ok (linear-non-composite-test-single-layer))
    (ok (linear-non-composite-test-single-layer-no-bw))))

;; But combined with composite, the second call of matmul will produce shape-error???
(defun linear-composite-test-single-layer ()
  (let ((model (LinearLayer 5 2)))
    (let ((model (build (!mean (call model (randn `(2 5)))))))
      (forward model)
      ;; (forward model) <- is working
      )))

;; Even when composed, the problem remains
(defun linear-composite-test-two-layer ()
  (let ((model  (LinearLayer 5 3))
	(model1 (LinearLayer 3 2)))
    (let ((compiled-model (build (!mean (call model1 (call model (randn `(1 5))))))))
      (forward compiled-model))))

;; 原因は二つあった?
;; 遅延評価!tがうまいタイミングでAllocされなかった（解決済み）
;; Composite使ったmatmulが二回目で失敗（原因なぞ）

;; no-grad = Tだと発生しない (?)
;; no-grad = NILだと発生する (?)

;; save-for-backwardのMoveTensorが原因であるはず。。。 (違った)
;; -> system-lazy-save-for-backwardはちゃんと動いている

;; 多分どっちか：
;; -> Memory-PoolにCacheされたInputTensorをPermuteするのが悪いのか
;; -> Backwardの関数をコンパイルしてる途中で何らかの副作用があるのか？
;; -> Cacheされた関数？

;; Knwon Issue: 二回目のCallでmatmulに失敗する？

(deftest linear-layer-test-forward
  (testing "Forward with Composite. It should not produce any side effects."
    (ok (linear-composite-test-single-layer))
    (ok (linear-composite-test-single-layer))
    (ok (linear-composite-test-single-layer))))


;; ugokan
(deftest linear-composed-layer-test-forward
  (testing "Forward with composed composite. If there's any side effects, it should produce a memory-related error or segfault."
    (ok (linear-composite-test-two-layer))
    (ok (linear-composite-test-two-layer))
    (ok (linear-composite-test-two-layer))))

;; Regardless of composite use, it occurs

(defmacro with-model-parameters ((bind model) &body body)
  `(let ((,bind (nodevariables-parameters
		 (compiled-variables ,model))))
     ,@body))

;; Simple Case:
;; Adjustable-Symbol <- None
;; static-node       <- None
;;
;; Only using pure features in cl-waffe2
;; OK
(defun linearlayer-backward-test ()
  (progn;with-memory-pool
    (let* ((model (LinearLayer-Sequence 100 50 10))
	   (model (build (call model (ax+b `(10 100) -0.01 0.01))
			 :compile-mode :default)))
      (forward model)
      (backward model)
      (with-model-parameters (params model)
	;;(loop for p in params
	;;      do (print p))
	(every #'not-zero-p params)))))

(deftest linear-backward-test-only-with-principle-features
  (testing "Backward with composite, and there should not be any memory-error related to side effects."
    (ok (linearlayer-backward-test))
    (ok (linearlayer-backward-test))
    (ok (linearlayer-backward-test))))

;; Second Case:
;; Adjustable-Symbol <- None
;; static-node       <- T
;;
;; Using criterion
;; Here's not working...
;; Once the form below is called, memory-pool is destructed.
(defun linearlayer-backward-test-with-criterion ()
  (let* ((model (LinearLayer-Sequence1 100 50 10))
	 (model (build (!mean
			(softmax-cross-entropy
			 (call model (randn `(10 100)))
			 (randn `(10 10))))
		       :compile-mode :default)))
    (forward model)
    (backward model)
    (with-model-parameters (params model)
      ;;(loop for p in params
      ;;	    do (print (grad p)))
      (every #'not-zero-p params))))

(deftest linearlayer-backward-with-criterlion
  (testing "Forward with a cached function."
    (ok (linearlayer-backward-test-with-criterion))
    ;; Is the cached function, works well?
    (ok (linearlayer-backward-test-with-criterion))))


;; これからデバッグすること：
;; Traceのネストが深い理由
;; -> requires-grad=tのテンソルを作成した時毎回コンパイルしてたから（修正済み）

;; Linearを重ねた時に中間層のMatmulのgradが0 -> !tでtensor-vecしてないから (修正済み）

;; 層を重ねても動いてる

;; memory-poolをテストする
;; Cacheされた関数テスト <- ignoreのやつほんとに有効になってる？

;; どこのマクロの展開式がダメ？
;; 関数コンパイルして一回目は動作、二回目以降は動かない
;; forwardを何回呼び出しても変わらない 関数を何回呼び出すかである

;; with-no-gradで呼び出す分には副作用が発生しない。
;; やっぱりPermute*が原因だと思う。
;;

;; 二回目のXの入力が5 2 -> 2 5になってるけどどうして？
;; (call model ExistTensor) するとX
;; (call model Copy) nara Ok

;; **randnのShapeをCopyしたら動いた WHY??**
;; `(1 2 ...) <- 参照渡しだっけ？
(defun matmul-bug-case ()
  (let ((model (LinearLayer 5 2)))
    (let ((model (build (!mean (call model (randn `(2 5))))
			:compile-mode :safety)))
      (forward model)
      (forward model)
      )))

(defmodel (Softmax-Model (self)
	   :where (X[~] -> [~])
	   :on-call-> ((self x)
		       (declare (ignore self))
		       (let* ((x1 (!sub x (!mean x  :axis 1 :keepdims t)))
                              (z  (!sum   (!exp x1) :axis 1 :keepdims t)))
                         (!div (!exp x1) z)))))

;; It is now working
(defun softmax-same-case? ()
  (let ((model (softmax-model)))
    (let ((model (build (!mean (call model (randn `(2 5)))))))
      (forward model))))

(deftest softmax-no-side-effect-call-of-composite
  (testing "Defining a static composite."
    (ok (softmax-same-case?))
    (ok (softmax-same-case?))
    (ok (softmax-same-case?))))

(defun fw-change-shape-test ()
  (let ((model (build (call (LinearLayer-Sequence 10 5 2)
			    (make-input `(batch-size 10) :X))
		      :compile-mode :safety)))
    (set-input model :X (randn `(10 10)))
    (forward model)
    (set-input model :X (randn `(20 10)))
    (forward model)
    (set-input model :X (randn `(5 10)))
    (forward model)
    model))

(deftest forward-with-different-shape
  (testing "Changing dynamic shapes after compilation."
    (ok (fw-change-shape-test))))

(defun fw-and-bw-test ()
  (let* ((linear (LinearLayer-Sequence 10 5 2))
	 (model (build (call linear
			     (make-input `(batch-size 10) :X)))))
    (set-input model :X (ax+b `(10 10) 0.0 1.0))
    (forward model)
    (backward model)
    
    ;;(with-model-parameters (params model)
    ;;  (loop for p in params
;;	    do (print (grad p))
;;	    do (print (tensor-vec (grad p)))))
    (forward model)
    (backward model)
  ;;  (with-model-parameters (params model)
    ;;  (loop for p in params
;;	    do (print (grad p))
;;	    do (print (tensor-vec (grad p)))))
    (forward model)
    (backward model)
  ;;  (with-model-parameters (params model)
    ;;  (loop for p in params
;;	    do (print (grad p))
;;	    do (print (tensor-vec (grad p)))))

    (forward model)
    (backward model)
    ))

(defun fw-and-bw-test-criterion ()
  (let* ((model (LinearLayer-Sequence1 100 50 10))
	 (model (build (!mean
			(softmax-cross-entropy
			 (call model (make-input `(batch-size 100) :X))
			 (make-input `(batch-size 10) :Y)))
		       :compile-mode :safety)))
    (set-input model :X (randn `(10 100)))
    (set-input model :Y (randn `(10 10)))

    (forward model)
    (backward model)

    (with-model-parameters (param model)
      (loop for p in param
	    do (grad p)))

    ;; Segfault here.
    (forward model)
    (backward model)

    (with-model-parameters (param model)
      (loop for p in param
	    do  (grad p)))
    T))

(deftest multiple-time-call-of-compiled-model
  (testing "Tests forward and backward with changing dynamic shapes multiple times."
    (ok (fw-and-bw-test))
    (ok (fw-and-bw-test-criterion))))


;; Gradients are decayed well?
;; Defines a model
(defsequence Simple-MLP (in-features hidden-dim)
	     (LinearLayer in-features hidden-dim t)
	     (asnode #'!sigmoid)
	     (LinearLayer hidden-dim 1 t))

;; Constructs/Compiles the neural network
(defun build-mlp-model (in-features hidden-dim &key (lr 1e-1))
  (let* ((lazy-loss (MSE (make-input `(batch-size 1) :TrainY)
			 (call
			  (Simple-MLP in-features hidden-dim)
			  (make-input `(batch-size ,in-features) :TrainX))))
	 (model (build (!mean lazy-loss) :inputs `(:TrainX :TrainY))))

    ;; Initializes and hooks AbstractOptimizers
    (mapc (hooker x (cl-waffe2/optimizers:SGD x :lr lr)) (model-parameters model))
    model))

;; Calls forward/backward propagations, and optimizes.
(defun step-train (model train-x train-y)
  (let ((act-loss (tensor-vec (forward model train-x train-y))))
    (backward model)
    (mapc #'call-optimizer! (model-parameters model))
    (aref act-loss 0)))

(defun grad-decay-test (&key
			  (batch-size 100)
			  (iter-num 3000))
  (let* ((X (proceed (!sin (ax+b `(,batch-size 100) 0.01 0.1))))
 	 (Y (proceed (!cos (ax+b `(,batch-size 1)   0.01 0.1))))
	 (model (build-mlp-model 100 10 :lr 1e-3))
	 (first)
	 (end))
    
    (loop for nth-epoch fixnum upfrom 0 below iter-num
	  do (let ((out (step-train model X Y)))
	       (if (null first) (setq first out))
	       (setq end out)))
    (> first end)))

(deftest grad-decay-test
  (testing "Tests the loss function converage using a small MLP model"
    (ok (grad-decay-test))))

(deftest grad-decay-cached-test
  (testing "Tests a small MLP model training using cached composite."
    (ok (grad-decay-test))))

(deftest row-major-grad-decay-test
  (testing "Testing the training using row-major order matrices"
    (ok (cl-waffe2::with-row-major (grad-decay-test)))))


