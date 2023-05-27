
(in-package :cl-waffe2/backends.lisp)

(defparameter *available-dtype-list*
  `(:double
    :float
    :uint32
    :uint16
    :uint8
    :int32
    :int16
    :int8
    :bit))

(defparameter *available-lisp-type* (map 'list #'dtype->lisp-type *available-dtype-list*))

(defun symb (&rest inputs)
  (intern (with-output-to-string (out) (dolist (sym inputs) (princ sym out)))))


(defun map-tree (fn tree)
  (let ((tree (funcall fn tree)))
    (if (listp tree)
        (mapcar (lambda (subtree)
                  (map-tree fn subtree))
                tree)
        tree)))

(defmacro define-with-typevar ((function-name type-ident)
			       (&rest args)
			       &body
				 body
			       &aux
				 (type-space (gensym "TYPE-KEY")))
  `(progn
     (defgeneric ,function-name (,type-space))

     ,@(map
	'list
	#'(lambda (type-key type)
	    `(defmethod ,function-name ((,type-space (eql ,type-key)))
	       #'(lambda (,@args)
		   ,@(map-tree
		      #'(lambda (obj)
			  (typecase obj
			    (symbol
			     (if (equal (symbol-name obj)
					(symbol-name type-ident))
				 type
				 obj))
			    (T obj)))
		      body))))
	*available-dtype-list* *available-lisp-type*)))

(define-with-typevar (add-test1 u) (x y)
  (declare (optimize (speed 3) (safety 0))
	   (type u x y))
  (the u (+ x y)))
