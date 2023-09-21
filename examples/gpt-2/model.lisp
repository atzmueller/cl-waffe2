
(in-package :gpt-2-example)

;; 
;; [TODO] Opt: Compiling !matmul
;;        Use: Standard APIs

(defparameter *model-params*
  `((:n-vocab . 50257)
    (:n-ctx   . 1024)
    (:n-emb   . 768)
    (:n-head  . 12)
    (:n-layer . 12)))

(defmacro with-gpt2-config ((&key
			       (n-vocab 50257)
			       (n-ctx 1024)
			       (n-emb 768)
			       (n-head 12)
			       (n-layer 12))
			    &body
			      body)
  `(let ((*model-params*
	   `((:n-vocab . ,,n-vocab)
	     (:n-ctx   . ,,n-ctx)
	     (:n-emb   . ,,n-emb)
	     (:n-head  . ,,n-head)
	     (:n-layer . ,,n-layer))))
     ,@body))

(defun read-config (keyword)
  "(read-config :n-vocab) ;; => 50257"
  (let ((keyword (if (keywordp keyword)
		     keyword
		     (intern (format nil "~a" keyword) "KEYWORD"))))
    (let ((result (find keyword *model-params* :test #'eql :key #'car)))
      (if result
	  (cdr result)
	  (error "No such a keyword: ~a" keyword)))))


;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;  Model definitions
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defmodel (GPT2Layer (self orig save-dir nth-layer)
	   :slots ((orig :initarg :orig :initform nil) ;; The GPT2 Model it belonging to
		   (ln-1-g :initform nil)
		   (ln-1-b :initform nil)
		   
		   (ln-2-g :initform nil)
		   (ln-2-b :initform nil)

		   ;; Attention
		   (attn-attn-w :initform nil)
		   (attn-attn-b :initform nil)

		   (attn-proj-w :initform nil)
		   (attn-proj-b :initform nil)

		   ;; MLP
		   (mlp-fc-w :initform nil)
		   (mlp-fc-b :initform nil)

		   (mlp-proj-w :initform nil)
		   (mlp-proj-b :initform nil)

		   (nth-layer :initarg :nth-layer :initform nil))
	   :on-call-> gpt2layer-call)
  (let* ((layer-dir (format nil "~a/h~a" save-dir nth-layer)))
    ;; layer-dir = save_dir/hN/...
    (setf (slot-value self 'ln-1-g)      (load-npy "~a/ln_1/g.npy" layer-dir)
	  (slot-value self 'ln-1-b)      (load-npy "~a/ln_1/b.npy" layer-dir)

	  (slot-value self 'ln-2-g)      (load-npy "~a/ln_2/g.npy" layer-dir)
	  (slot-value self 'ln-2-b)      (load-npy "~a/ln_2/b.npy" layer-dir)

	  (slot-value self 'attn-attn-w) (load-npy "~a/attn/c_attn/w.npy" layer-dir)
	  (slot-value self 'attn-attn-b) (load-npy "~a/attn/c_attn/b.npy" layer-dir)

	  (slot-value self 'attn-proj-w) (load-npy "~a/attn/c_proj/w.npy" layer-dir)
	  (slot-value self 'attn-proj-b) (load-npy "~a/attn/c_proj/b.npy" layer-dir)

	  (slot-value self 'mlp-fc-w)    (load-npy "~a/mlp/c_fc/w.npy" layer-dir)
	  (slot-value self 'mlp-fc-b)    (load-npy "~a/mlp/c_fc/b.npy" layer-dir)

	  (slot-value self 'mlp-proj-w)  (load-npy "~a/mlp/c_proj/w.npy" layer-dir)
	  (slot-value self 'mlp-proj-b)  (load-npy "~a/mlp/c_proj/b.npy" layer-dir))))

;; Custom printings
(defmethod on-print-object ((model GPT2Layer) stream)
  (format stream "~%N_LAYER=~a" (slot-value model 'nth-layer)))	  

;; Forward process of gpt2-layer
(defmethod gpt2layer-call ((self GPT2Layer) x past)
  (declare (type AbstractTensor x)
	   (type (or null AbstractTensor) past))
  (with-slots ((orig orig)
	       (ln-1-g ln-1-g)
	       (ln-1-b ln-1-b)
	       (ln-2-g ln-2-g)
	       (ln-2-b ln-2-b)
	       (mlp-fc-w mlp-fc-w)
	       (mlp-fc-b mlp-fc-b)
	       (mlp-proj-w mlp-proj-w)
	       (mlp-proj-b mlp-proj-b)
	       (attn-attn-w attn-attn-w)
	       (attn-attn-b attn-attn-b)
	       (attn-proj-w attn-proj-w)
	       (attn-proj-b attn-proj-b))
      self

    ;; GPT2Layer = Block(LayerNorm, Attention, LayerNorm, MLP)
    (let* ((present nil)
	   (attn
	     (call-> x
		     (asnode #'LayerNorm-Revisit ln-1-g ln-1-b)
		     ;; Projection: 786 -> 786*3		    
		     (asnode #'!matmul attn-attn-w) ;; X[Batch N Embedding_Dim] @ W[786 2304] + B[2304]
		     (asnode #'!add (%transform attn-attn-b[i] -> [~ i]))
		     (assetq (nil present) #'SelfAttention past orig) ;; NIL, PRESENT <- SelfAttention(past, orig-model)
		     (asnode #'!matmul attn-proj-w)
		     (asnode #'!add (%transform attn-proj-b[i] -> [~ i]))))
	   (x (!add x attn)) ;; Residual Connection
	   (m
	     (call-> x
		     ;; Feed Forward Network
		     (asnode #'LayerNorm-Revisit ln-2-g ln-2-b)
		     (asnode #'!matmul mlp-fc-w) ;; X(768 N).T @ W(1 768 3072) + B(3072)
		     (asnode #'!add    (%transform mlp-fc-b[i]   -> [~ i]))
		     (asnode #'!gelu)
		     (asnode #'!matmul mlp-proj-w)
		     (asnode #'!add    (%transform mlp-proj-b[i] -> [~ i])))))
      ;; Residual Connection
      (!add x m))))


(defmodel (GPT2 (self &key (save-dir "./examples/gpt-2/assets/models/gpt-2-117M/gpt2-waffe2/model"))
	   :slots ((ln        :initform nil)
		   (embedding :initform nil)
		   (wte       :initform nil)
		   (wpe       :initform nil)
		   (layers    :initform nil)))
  (let ((n-layer (read-config :n-layer)))    
    (setf (slot-value self 'embedding) (GPT2PositionalEmbedding
					(read-config :n-vocab)
					(read-config :n-ctx)
					(read-config :n-emb))
	  (slot-value self 'wte)    (load-npy "~a/wte.npy" save-dir)
	  (slot-value self 'wpe)    (load-npy "~a/wpe.npy" save-dir))

    (let* ((alpha (load-npy "~a/ln_f/g.npy" save-dir))
	   (beta  (load-npy "~a/ln_f/b.npy" save-dir)))
      ;; Initializing alpha beta when creating LayerNorm
      ;; Is nothing but waste of memory??
      (setf (slot-value self 'ln) (LayerNorm (shape alpha))
	    (alpha-of (slot-value self 'ln)) alpha
	    (beta-of (slot-value self 'ln)) beta))    
    
    (setf (slot-value self 'layers)
	  (loop for layer-n upfrom 0 below n-layer
		collect (GPT2Layer self save-dir layer-n)))))

(defmethod call ((self GPT2) &rest inputs)
  ;; Inputs: Prev Past1 Past2 Past3 ...
  (let ((prev        (car inputs))
	(layer-pasts (cdr inputs))
	(presents nil))
    (with-slots ((layers layers) (embedding embedding) (wte wte) (wpe wpe) (ln ln)) self
      ;; Return: (values output presents)
      (values
       (call->
	(make-input `(batch-size N0 embedding-dim) nil)
	
	;; Composes: [PE] -> [N * Layers] -> LayerNorm
	(asnode #'(lambda (x) (call embedding prev wte wpe x)))
	(asnode
	 #'(lambda (x-out &aux (present nil))
	     (loop for layer in layers
		   for n upfrom 0 do
		     (multiple-value-setq (x-out present)
		       (call layer x-out (nth n layer-pasts)))
		     (push present presents))
	     x-out))
	ln)
       presents))))

;; Customized printings
(defmethod on-print-object ((model GPT2) stream)
  (format stream "~%  [Layers]:~%~a~%"
	  (with-output-to-string (out)
	    (dolist (layer (slot-value model 'layers))
	      (format out "~a~%" layer)))))

(defmethod lm-head ((self GPT2) x)
  (!matmul (!rankup x -1) (!t (slot-value self 'wte))))

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;  Inference/Exports
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defun compile-gpt2-model (&key (use-instead nil) (disassemble nil))
  (let* ((model (or use-instead (GPT2)))
	 (model-past
	   (build
	    (call model
		  (make-input `(batch-size N0) :prev)
		  (make-input `(batch-size N1 embedding-dim) :past))
	    :inputs `(:prev :past)))
	 (model-no-past
	   (build
	    (call
	     model
	     (make-input `(batch-size N0) :prev)
	     nil)
	    :inputs `(:prev))))

    (when disassemble
      (disassemble-waffe2-ir
       (call model (make-input `(batch-size N0) :prev) nil)))
    
    (values
     model
     #'(lambda (prev &rest past)
	 (if (null past)
	     (forward model-no-past prev)
	     (apply #'forward model-past prev past))))))

(defun start-token () (gethash "<|endoftext|>" *encoder-json*))

(defun gpt2-inference (model compiled-model source input &key (length 10) (temperature 1.0))
  (declare (ignore temperature))
  ;;mem-k mem-v: Not used for a now
  (setf (slot-value model 'memory-k) nil
        (slot-value model 'memory-v) nil)

  (let ((result))
    (loop with slen fixnum   = (second (shape input))
	  with batch-size    = (car    (shape source))
	  with embedding-dim = (third  (shape source))
	  for nth fixnum upfrom slen below (+ slen length) do
	    (format t "~a/~a...~%" nth (+ slen length))
	    (setq source (get-input compiled-model :x-source))
	    (setq input  (get-input compiled-model :x-input))
	    (let* ((N (second (shape source))))
	      (let* ((out     (forward compiled-model))
		     (tmp     (make-input `(1 ,N ,(third (shape out))) nil))
		     (tmp     (->contiguous (!view (!move tmp out) 0 -1)))
		     (out     (lm-head model tmp))
		     (idx     (tensor-vec (proceed (->scal (!argmax (!softmax out) :axis 1))))))

		(set-input compiled-model :x-source (make-tensor `(,(car (shape source)) ,(1+ N) ,(third (shape source)))))
		(extend-source-input-2d compiled-model :x-input  input  nth (coerce idx 'single-float))
		(push idx result))))
    (reverse result)))

;; Workload:
;; 1. inference anyway
;; 2. do a cache
;; Invokes REPL form

;; It was a bright cold day in April, and the clocks were striking thirteen. Winston Smith, his chin nuzzled into his breast in an effort to escape the vile wind, slipped quickly through the glass doors of Victory Mansions, though not quickly enough to prevent a swirl of gritty dust from entering along with him.

(defun launch-repl (&key (use-model nil) (length 50) (temperature 1.0))
  (format t "length=~a~%" length)
  (with-no-grad
    (let ((model (or use-model (GPT2))))
      (format t "[INFO] The model was restored from the trained weight!~%")
      (print model)
      (when (null *encoder-json*)
	(format t "[INFO] Loading encoder...~%")
	(load-bpe-merges)
	(load-encoder-json))

      (loop named repl while t do
	(format t "~%Type \"quit\" to exit, \"benchmark\" to start profiling.~%>Type anything to start generating a sentence.~%Note that GPT2 Inference is stil unstable...~%")
	(let ((input (read-line)))
	  
	  (when (equal input "quit")
	    (format t "Good bye. You can use (gpt-2-example:launch-repl) to invoke me again. ~%")
	    (return-from repl))

	  (format t "[INFO] Compiling GPT2 Model...~%")
	  
	  (let* ((source         (make-input `(1 N 768) :x-source))  ;; (Batch_Size Sentence_Length Embedding_dim)
		 (input-tensor   (make-input `(1 N)     :x-input))   ;; (Batch_Size Sentence_Length)
		 (compiled-model (time (build (call model source input-tensor)))))
	    (time (build (call model source input-tensor)))
	    
	    (if (equal input "benchmark")
		(progn
		  (format t "N_SAMPLE=10, LENGTH=10~%")
		  (proceed-bench
		   (call model (ax+b `(1 10 768) 0 0) (uniform-random `(1 10) 0 100))
		   :n-sample 10))
		(let* ((input-sentence (encode-sentence input))
		       (initial-length (second (shape input-sentence)))
		       (input-source   (ax+b `(1 ,initial-length 768) 0 0)))
		  
		  ;; X Embedding ... (1 N 768)
		  ;; X Sparse    ... (1 N)

		  (set-input compiled-model :x-source input-source)
		  (set-input compiled-model :x-input  input-sentence)
		  
		  (let ((generated-sentence-list (gpt2-inference model compiled-model input-source input-sentence :length length :temperature temperature)))
		    (format t "~%GPT2> ~a~%" (decode-sentence generated-sentence-list)))
		  
		  (return-from launch-repl)))))))))


