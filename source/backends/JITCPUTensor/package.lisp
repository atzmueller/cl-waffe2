
(in-package :cl-user)

(defpackage :cl-waffe2/backends.jit.cpu
  (:documentation ":cl-waffe2/backends.jit.cpu provides JIT compiler from cl-waffe2 codes to well vectorized C codes.")
  (:use :cl
   :cl-waffe2/distributions
        :cl-waffe2/vm.generic-tensor
   :cl-waffe2/vm.nodes
        :cl-waffe2/base-impl)
  (:export
   #:*default-c-compiler*
   #:*compiler-flags*
   #:*viz-compiled-code*
   #:JITCPUTensor
   #:JITCPUScalarTensor
   #:enable-cpu-jit-toplevel
   #:with-cpu-jit))

(in-package :cl-waffe2/backends.jit.cpu)

(defun compose (&rest fns)
  "fn_1(fn_2(fn_n...))"
  (if fns
      (let ((fn1 (car (last fns)))
            (fns (butlast fns)))
        #'(lambda (&rest args)
            (reduce #'funcall fns
                    :from-end t
                    :initial-value (apply fn1 args))))
      #'identity))

(defun symb (&rest inputs)
  (intern (with-output-to-string (out) (dolist (sym inputs) (princ sym out)))))

(defun delete-newlines (string)
  (cl-ppcre:regex-replace-all #\newline string " "))
