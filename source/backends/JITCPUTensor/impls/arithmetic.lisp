
(in-package :cl-waffe2/backends.jit.cpu)


;; ~~ List of arithmetic operations in cl-waffe2 ~~~~~~~~~~~~
;; Matrix and Matrix Operations:

;; AddNode/SubNode/MulNode/DivNode + InverseNode/MoveTensorNode



;; Arithmetic operation family is originally declared as:
;; X <- op(X, Y)

;; First, Try Solving the loop order
;; If the order is complicated, set reject-p=nil
;; And solve-loop-order ...

;; 1. Keyの追加
;; 2. Permutionが複雑じゃなかったら: -> JITCPUTensor以外のForwardにRedirectする？

(macrolet ((define-arith-impl (name lisp-op op-name)
	     `(progn
		(define-impl (,name
			      :device JITCPUTensor
			      :extends (CPUJIT-Blueprint))
			     :forward ((self x y)
				       ;; Called at a Toplevel
				       (progn
					 (setf (blueprint-use-var self) `(,x ,y))
					 (setf (blueprint-opecode self) ',lisp-op)
					 nil)

				       ;; Embedding into JIT
				       `(progn ,x)))

		(defmethod translate-op ((opcode (eql ',lisp-op)) opAST &rest args)
		  (make-inst :modify
			     ,op-name
			     (car args)
			     (cdr args))))))
  (define-arith-impl AddNode + "+=")
  (define-arith-impl SubNode - "-=")
  (define-arith-impl MulNode * "*=")
  (define-arith-impl DivNode / "/="))

(define-impl (MoveTensorNode :device JITCPUTensor :extends (CPUJIT-Blueprint))
	     :forward ((self out target)
		       (progn
			 (setf (blueprint-use-var self) `(,out ,target))
			 (setf (blueprint-opecode self) 'move)
			 nil)
		       `(progn ,out)))

(defmethod translate-op ((opcode (eql 'move)) opAST &rest args)
  ;; A <- B
  (let ((self (tensor-backward (opAST-car opAST))))
    (if (movetensor-ignore-me self)
	(make-inst :set     "="   (car args) (cdr args))
	(make-inst :modify  "="   (car args) (cdr args)))))
