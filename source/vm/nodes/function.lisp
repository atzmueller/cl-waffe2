
(in-package :cl-waffe2/vm.nodes)

;; The file function.lisp provides a system on interacting Lazy-Evaluated Nodes and Toplevel functions:
;;
;; Composite <-> Function
;; Node      <-> Function
;;

(defmodel (DotProduct (self)
	   :where ([~] [~] -> [~])
	   :on-call-> ((self x y)
		       (declare (ignore self))
		       (cl-waffe2/base-impl:!sum (cl-waffe2/base-impl:!mul x y)))))

(defun composite->function (~ composite function-name
			    &key
			      (dtype :float)
			      (order :column)
			      (scalar-p nil)
			      (compile-mode :default))
  "
## [function] composite->function

Tracing definition of given composite, the function `composite->function` returns a compiled-lambda function.

Return: (values input-names lambda-function)
"

  ;; Reading where
  ;; where as shape
  ;; set ~ = given ~ (NIL IS OK)

  ;; Tracing
  ;; Building
  ;; Lambda Encapsulate

  ;; Receives Input Tensors
  (let* ((inputs (composite-input-tensor composite ~
					 :dtype dtype
					 :order order
					 :scalar-p scalar-p))
	 (namelist (or (composite-symbol-names composite)
		       (loop for i upfrom 0 below (length inputs)
			     collect (nth-subscript i))))
	 (result (apply #'call composite inputs)))
    (with-no-grad
      (let ((compiled-kernel (cl-waffe2/vm.generic-tensor:build result :compile-mode compile-mode)))
	`(defun ,function-name (,@namelist)
	   ,@(loop for tensor in inputs
		   for name in namelist
		   collect `(set-input ,compiled-kernel ,(tensor-name tensor) ,name))
	   (forward ,compiled-kernel))))))


(defmacro define-composite-det-function (composite-init-form function-name)
  "
## [macro] define-composite-det-function

"

  `(eval (composite->function `(a b) ,composite-init-form ',function-name)))

(define-composite-det-function (DotProduct) !dotproduct)

;; define-composite-undetermined-function
;; define-composite-function

  
(defun test-composite-f ()
  (let ((model (DotProduct)))
    (composite->function
     (dim->input-shape 2)
     model)))

(defmacro def-composite->function (composite-name function-name)
  "
## [macro] composite->function

The macro `define-composite-function` traces the computation node of given Composite, `composite-name`, defining a function."

  ;; Is there ~ parameter?
  ;; If True -> We need a method in order to dispatch the appropriate dim
  ;; Otherwise -> We need a single function

  
  
  
  
  )


(defmacro define-as-operation (toplevel)
  "
## [macro] define-as-operation
AsNode but defines the function TOPLEVEL.
"
  )
