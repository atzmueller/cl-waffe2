
(in-package :cl-waffe2/backends.jit.cpu)

(defclass JITCPUTensor (cl-waffe2/backends.cpu:CPUTensor) nil
  (:documentation "
## [AbstractTensor] JITCPUTensor
"))

(defmethod current-backend-state ((backend-name (eql 'JITCPUTensor)))
  (format nil "compiler=~a flags=~a viz=~a"
	  *default-c-compiler*
	  *compiler-flags*
	  *viz-compiled-code*))

(deftype JITAbleTensors ()
  "JITAbleTensor is tensors which are subject to be compiled: JITCPUTensor and ScalarTensor."
  `(or JITCPUTensor))

(defun enable-cpu-jit-toplevel (&key
				  (more-devices)
				  (compiler "gcc")
				  (viz-compiled-code nil)
				  (openmp nil)
				  (flags '("-fPIC" "-O3" "-march=native")))
  "
## [function] enable-cpu-jit-toplevel

```lisp
(enable-cpu-jit-toplevel (&key
			  (more-devices)
			  (compiler \"gcc\")
			  (viz-compiled-code nil)
                          (openmp nil)
			  (flags '(\"-fPIC\" \"-O3\" \"-march=native\"))))
```

Sets `JITCPUTensor` and `JITCPUScalarTensor` to the top priority of backends. Place this function at the top of your code where JIT Compiling is needed. Of course, `JITCPUTensor` is developed as a one of `external backends` in cl-waffe2, therefore Local JIT compilation with the `with-devices` macro is another valid option.

### Inputs

`more-devices[List]` specify the list of device names. they have lower priority than `JITCPUTensor`

`viz-compiled-code[boolean]` Set t to display the compiled c codes.

`openMP[boolean]` set T to use OpenMP.
"
  (setf *default-c-compiler* compiler
	*viz-compiled-code* viz-compiled-code
	*use-open-mp* openMP
	*compiler-flags* flags)
  (apply #'cl-waffe2:set-devices-toplevel 'JITCPUTensor more-devices)
  t)

(defmacro with-cpu-jit ((&rest more-devices) &body body)
  "
## [macro] with-cpu-jit

Under this macro, two backends (`JITCPUTensor` and `JITCPUScalarTensor`) are installed at the top of the priority list.
"
  `(with-devices (JITCPUTensor ,@more-devices)
     ,@body))

;; Memo: https://groups.google.com/g/comp.lang.lisp/c/4aDbcVUBraQ
;; Pinning Arrays?
;; TODO: Do it outside call-with-view
(declaim (inline tensor-ptr))
(defun tensor-ptr (tensor)
  (declare (type JITCPUTensor tensor))
  #+sbcl
  (sb-sys:vector-sap (sb-ext:array-storage-vector (the (simple-array * (*)) (tensor-vec tensor))))
  #-(or sbcl)
  (error "JITCPUTensor requires SBCL to access the storage vector!"))

