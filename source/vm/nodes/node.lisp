
(in-package :cl-waffe2/vm.nodes)

(defparameter *enable-broadcasting-auto* t) ;; This parameter never exported/modified by users, just used to prevent recursively call of forward
(defparameter *restart-variable-from* nil)


;; AbstractNode is all about cl-waffe2 -
(defclass AbstractNode ()
  ((where-decl :initarg :where-decl :initform nil :accessor read-where)
   (subscript  :initarg :subscript  :initform nil :accessor subscript-of)
   
   ;; Shape Transmission States
   ;; Broadcastable Version
   (function-node
    :initarg
    :function-node
    :reader abstractnode-node
    :type function) ;; [x ~ y] [y z] -> [z x]

   ;; Not broadcastable Version
   (function-node1
    :initarg
    :function-node1
    :reader abstractnode-node1
    :type (or null function)) ;; [x y] [y z] -> [z x], ~ is removed. If ~ isn't used at function-node, set nil


   ;; Broadcastable Positions
   (uprank-state :initform nil :initarg :uprank-state :reader uprank-state :type list)
   (transmission-state :initarg :transmission-state :reader transmission-state :type list)

   ;; Utils
   (ignore-shape-error :initform nil :accessor ignore-shape-error)
   (expected-output-shape :initform nil :type list :accessor node-output-shape) ;; <- Debug Information
   (passed-at-least-once :initform nil :accessor node-passed-p :type boolean)   ;;

   ;; [TODO] (tpsort-id :initform (gensym)) ...
   
   ;; :save-for-backward
   (sv4bw-places :initform nil :type list :accessor node-sv4bw) ;; (list AbstractTensor ...)
   
   ;; For cl-waffe2 VM
   (out-to    :initform nil :accessor node-out-to)
   (out-sizes :initform nil :accessor node-out-sizes))
  (:documentation "

## [class] AbstractNode

AbstractNode is a CLOS class to represent operations.

Can be created by a function `(AbstractName ...)` declared by the defnode macro.

In order to step the computation: `(forward node arg1 arg2 ...)` (using a `call` instead of `forward` is ok)

And backward: `(backward node prev-gradient arg1 arg2 ...)`

"))


(defmethod test-and-forward-shape ((node AbstractNode) &rest previous-shape) (funcall (abstractnode-node node) previous-shape))


(defun describe-problems (error-node detected-errors inputs outputs)
  "Creates a report of shape-error"
  ;; Enhancement:
  ;; Restart-Case
  ;; [Fix-Definition-And-Step]
  ;; [Replace-Shape-And-Step]
  ;; More Details:
  ;; Displays [pre-|post-]computation node <<!!!
  ;; TODO: make it more intuitive....
  (shaping-error "~a" (build-shape-error :forward error-node (read-where error-node) inputs outputs detected-errors)))

;; Forward:  f(input-state) -> output-state
;; Backward: g(output-state) -> input-state

(defgeneric forward  (node &rest inputs) (:documentation "
## [generic] forward

(TODO)

"))

(defgeneric backward (node &rest inputs) (:documentation "
## [generic] backward

(TODO)

"))

;; Issues of current broadcasting semantic?
;; Can't distinguish it:
;;  (3 -1 3)
;;  (3 3 -1)
;;
;;  (-1 3 3)
;;     (3 3)
;;

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;  Forward Mode Network Construction
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			       
(defmethod forward :around ((node AbstractNode) &rest inputs)
  ;; With the forward method, AbstractNode is invoked and
  ;;  1. Dispatches broadcasting-auto
  ;;  2. Records the computation node lazily
  ;;  3. Detects Shapeing-Error
  ;;  4. Adds save4bw
  (assert (every #'(lambda (x) (typep x 'AbstractTensor)) inputs)
      nil
      "(forward node &rest inputs)
                      ^ every input should be AbstractTensor
butgot: ~a"
      (find 'AbstractTensor inputs :test #'(lambda (x y) (not (typep y x)))))


  (let* ((save-for-backward (node-save-for-backward node))
	 (inputs (or (when *restart-variable-from* inputs) ;; No additional save-for-backward is created.
		     ;; attribute Save4backward states
		     (loop for i in inputs
			   for nth upfrom 0
			   if (and (not *no-grad*)
				   (cl-waffe2/vm.generic-tensor::ancestor-param-p i)
				   (nth nth save-for-backward)) ;; The node declared as so?
			     collect (or
				       (system-lazy-set-save-for-backward i)
				       i)
			   else
			     collect i)))
	 (transition-function     (abstractnode-node node))  ;; original subscript
	 (transition-function-sub (abstractnode-node1 node)) ;; subscript without ~
	 (pointer-states          (transmission-state node)) ;; <- what ptr/view to use?
	 (uprankable-list (uprank-state node))
	 ;; replace <1 x N> = -1 for instance
	 (input-states (map 'list #'shape inputs))
	 
	 ;; Records that Is it worth to trace backward?
	 (ancestor-param-p (some #'cl-waffe2/vm.generic-tensor:ancestor-param-p inputs)))
    ;; Detecting Shape-Error, And finds combinations that satisfies shape-requirement heuristic.
    ;; Input-State -> Output-State
    (multiple-value-bind (out-state detected-errors) (funcall transition-function input-states) ;; ... Finishes in < 1e-6 sec
      ;;(setq out-state (delete-broadcast out-state))
      ;; FixME: ~ = nil isn't allowed. [~ x] with (10) is unexpectedly invalid.

      (when detected-errors
	;; If any errors occured, try again with removing ~ from subscripts. (I know this behaviour is ugly.)

	(multiple-value-bind (out-state1 detected-errors-1) (funcall transition-function-sub input-states)
	  ;;(setq out-state1 (delete-broadcast out-state1))

	  ;; Enhancement
	  ;; CALL-VIEW-AND-CONTINUE
	  ;; If error is not originated from ~.

	  ;; The case when error continues...

	  (if (and detected-errors-1
		   (not (ignore-shape-error node)))
	      ;; There's no flexible tensor, then it is invalid.
	      ;; If there's any flexible tensor, uprank it and try again.

	      ;; The node is declared as uprankable
	      ;;  A[~ x]   B[x]   -> B[x]

	      ;; Uprankable Nodes are subject to broadcasted
	      (if (and *enable-broadcasting-auto*
		       (find t (mapcar #'(lambda (x y) (and (tensor-flexible-p x) y)) inputs uprankable-list)))
		  ;; Update ranks and try again...
		  (let* ((*enable-broadcasting-auto* nil)
			 (inputs-new (apply-broadcast input-states inputs uprankable-list))
			 (*restart-variable-from* inputs)) ;; (tensor-variable out) records the first call of tensors (top_inputs)
		    ;;  Forward:         Broadcast:          Restart
		    ;; 
		    ;; top_inputs -> View/Reshape/Uprank -> (forward ...)
		    ;; inputs-top -> inputs-new nodes are continuous.
		    ;; because inputs-new are made from inputs-top
		    (return-from forward (apply #'forward node inputs-new)))
		  ;; Otherwise the operation was invalid.
		  (describe-problems node detected-errors inputs out-state))
	      (setq out-state out-state1))))

      ;; TODO: When Dynamic-Mode
      ;; Call (construct-forward) and eval it here.
      
      ;; Forward:  Input-State  -> Output-State
      ;; Backward: Output-State -> Input-State

      ;; Forward:
      ;; [30 10] + [30 10] -> [10 10] -> [5 5]
      ;; Memo: Sharing Allocated memory between f and b
      ;; can be realised with self ...
      ;; recompute grad

      (setq out-state (parse-broadcasted-shape out-state))
      (setf (node-output-shape node) out-state)

      (let* ((forward-form (call-next-method))
	     (next-tensor
	       (loop for shape in out-state
		     for nth-arg upfrom 0
		     for extend-from in pointer-states
		     ;; Make -> ScalarTensor if shape = (1)
		     collect (let* ((next-tensor
				      (make-input shape nil
						  :create-from (when extend-from
								 (nth extend-from inputs))
						  :scalar-p (out-scalar-p node)
						  :dtype (dtype (nth (or extend-from 0) inputs))
						  :order (order (nth (or extend-from 0) inputs))))
				    (state (make-statecontainer
					    :forward-out-form forward-form
					    :forward-n-out  (length out-state)
					    :backward-n-out (length input-states))))

			       ;; Extend Views, Strides, Orig-Shapes, etc..
			       ;; Exntend Permuted Stride Orders

			       (when extend-from
				 ;; FixME: A[i j] -> A[j i] is invalid because before and after the operation, indicates the same pointer but shapes arenot the same.
				 ;; Detect Errors
				 (let ((input (nth extend-from inputs)))
				   ;; Extend View Forms
				   (setf (slot-value next-tensor 'cl-waffe2/vm.generic-tensor::orig-shape)
					 (slot-value input       'cl-waffe2/vm.generic-tensor::orig-shape)
					 
					 (tensor-view next-tensor)
					 (tensor-view input)
					 
					 (slot-value next-tensor 'cl-waffe2/vm.generic-tensor::tensor-id) (tensor-id input)

					 (tensor-name next-tensor) (tensor-name input)
					 (slot-value next-tensor 'cl-waffe2/vm.generic-tensor::projected-p)
					 (slot-value input 'cl-waffe2/vm.generic-tensor::projected-p)
					 
					 (cl-waffe2/vm.generic-tensor:tensor-stride next-tensor)
					 (cl-waffe2/vm.generic-tensor:tensor-stride input))

				   (when (cl-waffe2/vm.generic-tensor::vec input)
				     (setf (tensor-vec next-tensor) (tensor-vec input)
					   (cl-waffe2/vm.generic-tensor:tensor-initial-offset next-tensor) (cl-waffe2/vm.generic-tensor:tensor-initial-offset input)
					   (cl-waffe2/vm.generic-tensor::tensor-facet input) :exist))))
			       
			       (setf (cl-waffe2/vm.generic-tensor:ancestor-param-p next-tensor) ancestor-param-p)
			       (setf (tensor-out-n next-tensor)     nth-arg)
			       (setf (tensor-state next-tensor)     state)
			       (setf (tensor-backward next-tensor)  node)
			       (setf (tensor-variables next-tensor) inputs)
			       next-tensor))))

	(setf (node-out-sizes node) (map 'list #'shape next-tensor)
	      (node-out-to    node) next-tensor)

	;; Register what variables should be saved? or to where?
	(setf (node-sv4bw node)
	      (map 'list #'system-lazy-read-save-for-backward inputs))
	(apply #'values next-tensor)))))

(defmethod forward ((node AbstractNode) &rest inputs)
  (declare (ignore inputs))
  ;; Describe More Errors.
  (error "
forward: Couldn't step forward step of ~a because it is undefined.

(~a ...)
    └── Make sure that the node is created by this constructor
        which is automatically defined by the defnode macro.
"
	 node
	 (class-name (class-of node))))

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;  Reverse Mode Graph-Level Network Construction
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;; [TODO] :backward Shape-Error Detection here?
(defun make-backward (tensor dout)
  "
## [function] make-backward

```lisp
(make-backward tensor dout)
```
"
  (let ((node (tensor-backward tensor))
	(variables (tensor-variables tensor)))
    (declare (type AbstractNode node)
	     (type list variables))    

    (let* ((in-tensors (loop for var in variables
			     collect (or (system-lazy-read-save-for-backward var) var)))
	   (detach-states (map 'list #'detach-p in-tensors))
	   (dout-detach-p (detach-p dout)))

      (mapc #'(lambda (tensor) (setf (detach-p tensor) t)) in-tensors)
      (setf (detach-p dout) t)
      
      (let* ((out-toplevels (multiple-value-list (apply #'backward node dout in-tensors)))
	     (out-toplevels (if (every #'null out-toplevels) ;; no gradients?
				(return-from make-backward)
				out-toplevels))
	     (toplevel (loop for top in out-toplevels
			     for var in variables
			     collect (when (cl-waffe2/vm.generic-tensor::ancestor-param-p var)
				       top)))
	     (directions (loop for var in out-toplevels if var collect t else collect nil))
	     (out-toplevels-pswise out-toplevels)
	     (out-toplevels (loop for top in toplevel
				  for out in out-toplevels
				  if top collect out))
	     (toplevel (loop for top in toplevel if top collect top))
	     (toplevel (if toplevel (apply #'!system-lazy-values toplevel)))
	     (compiled  (multiple-value-list
			 (cl-waffe2/vm:compile-forward-and-backward toplevel
								    :need-backward nil
								    :fuse-p t
								    :compile-mode :fastest
								    :optimize-locality nil)))
	     (fw-iseq (car compiled))
	     ;;(leaves  (third compiled))
	     )

	(mapc #'(lambda (tensor state)
		  (setf (detach-p tensor) state))
	      in-tensors detach-states)
	(setf (detach-p dout) dout-detach-p)
	;;(cl-waffe2/vm::apply-in-place-mutation! fw-iseq leaves)
	(values
	 #'(lambda (dout-runtime &rest inputs-runtime)
	     (setf (tensor-vec dout) (tensor-vec dout-runtime))
	     (loop for act-val in inputs-runtime
		   for var     in variables
		   for place   in in-tensors
		   if (system-lazy-read-save-for-backward var)
		     do (if (null (cl-waffe2/vm.generic-tensor::vec (system-lazy-read-save-for-backward var)))
			    (error "cl-waffe2 VM Autograd: Save for backward isn't allocated because the forward step of ~a isn't called."
				   var))
		   else		     
		     do (setf (tensor-vec place) (tensor-vec act-val)))

	     (if cl-waffe2/vm::*under-benchmark-set* ;; If benchmarking mode, extends the state and proceed benchmarking...
		 (cl-waffe2/vm::benchmark-accept-instructions fw-iseq)
		 (cl-waffe2/vm:accept-instructions fw-iseq))
	     ;; When quitting mem-pool, the result is never freed.

	     (apply #'values (map 'list #'cl-waffe2/vm::maybe-read-result out-toplevels)))
	 fw-iseq
	 out-toplevels-pswise
	 directions)))))

(defmethod backward :around ((node AbstractNode) &rest inputs)
  (declare (ignore inputs))
  (when (not *no-grad*)
    (with-no-grad
      (with-shape-checkpoint (:backward node)
	(call-next-method)))))

(defmethod backward ((node AbstractNode) &rest inputs)
  (declare (ignore inputs))
  (error "backward: The computation node for reverse mode is disconnected at the ~a node.
This is because no any backward definition is provides for it. Make sure that your node has a :backward slot." node))

