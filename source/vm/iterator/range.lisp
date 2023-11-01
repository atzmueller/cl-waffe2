
(in-package :cl-waffe2/vm.iterator)

;; Range is designed to replace view.

;; Range = (LIST FROM TO STEP <<LazyAxis>>)

;; [TODO1]
;;  - package nicknames to all packs
;;  - make-tensor, make-input: ~ as a !flexible
;;  - Lazy...複数の引数
;;  - Dynamic-Shape 手動で帰れるようにする
;;  - LoopNode 実装 Dynamic-Shape更新するようにする

;; Dynamic-Shape 手動で変更する方法を提供しておく
;; Range ... Dynamic Shape, LazyAxis対応したい

;; Ranges should satisfy following properties:

;; - (Range 1 9) |
;; - (Range 1 9 3) | これ合成してなんでも表現できるようにする？

;; Lazy-Index-Components:
;;  lazy ... 複数の引数呼び出せればおk
;;  Creates a tensor of Shape
;;  (3 3)
;;  ((0 1 2)
;;   (2 3 4))

;; Range ... Index/Symbolが扱える
;; Reverse/Slice/Broadcastingが表現できる
;; Iterationが生成できる
;; Tを使える
;; FROM/TOのT = 行列の最後のサイズ
;; STEPのT    = broadcasting but 相手の方に合わせる
;; Broadcastingの状態= Tensor側に付与する (view.lisp)
;; Rangeはここでは触れない

;; Lazy-LoopとDynamic-Shapeの任意編集を組み合わせてDiagnoal実装可能?
;; view.lisp <-> iterator.lisp通信 (Parsing etc...)

(deftype Index-Symbol-T ()
  `(or fixnum symbol))

(defstruct (Range
	    (:constructor make-range (from to &optional (step 1))))
  (from from :type index-symbol-t)
  (to   to   :type index-symbol-t)
  (step step :type index-symbol-t))

(defun symbol-pprint-helper (value)
  "Displays the value as pretty as possible"
  (if (typep value 'symbol)
      (or
       (symbol-lazyaxis value)
       value)
      value))

(defun range-size (range)
  (declare (type range range))
  (make-lazyaxis
   `(floor
     (abs (- ,(range-from range)
	     ,(range-to   range)))
     (abs ,(range-step range)))))

(defun pprint-range-size (range)
  (declare (type range range))
  (make-lazyaxis
   `(floor
     (abs (- ,(symbol-pprint-helper (range-from range))
	     ,(symbol-pprint-helper (range-to   range))))
     (abs ,(symbol-pprint-helper (range-step range))))))

(defmacro do-range ((var range) &body body)
  "Creates an iteration following the instruction of range.
Range can include dynamic shape.

Note that iterations generated by do-range is NOT A THREAD_SAFE!!"
  (alexandria:with-gensyms (tmp a b c from below count)
    `(let* ((,a (maybe-observe-axis (range-from ,range)))
	    (,b (maybe-observe-axis (range-to   ,range)))
	    (,c (maybe-observe-axis (range-step ,range)))
	    (,from  (min ,a ,b))
	    (,below (max ,a ,b)))
       ;; When Observed Step is a negative number
       (if (< ,c 0)
	   (let ((,tmp ,below))
	     (setq ,below ,from
		   ,from  (+ ,c ,tmp))))
       
       (dotimes (,count (the (unsigned-byte 64) (maybe-observe-axis (range-size ,range))))
	 (let ((,var (+ ,from (* ,c ,count))))
	   (declare (type (unsigned-byte 64) ,var))
	   #|
	   For debugging
	   (assert
	    (and (< ,count  ,below)
		 (>= ,count ,from))
	    ()
	    "do-range: Assertion Failed because the ~a(=~a) isn't in the range of [~a, ~a)"
	    ',var
	    ,var
	    ,from
	     ,below)
	   |#
	   ,@body)))))

(defun range (from to &optional (step 1))
  "
## [function] range

```lisp
(range from to &optional (step 1))
```

Creates a range: `[from, to) where step=step`. This structure is dedicated to a do-range macro which generates an iteration following rules:

- starting from (min from, to)
- ends with (max from, to)
- if step < 0, the order is reversed.
- This macro asserts that `var` is in the range of [from, to).
"
  (flet ((parse (value)
	   (let ((out (make-lazyaxis value)))
	     (if (typep out 'LazyAxis)
		 (lazyaxis-symbol out)
		 out))))
    (let ((from (parse from))
	  (to   (parse to))
	  (step (parse step)))
      (assert (or
	       (not (numberp step))
	       (not (= step 0)))
	      ()
	      "range: do not create a range whose step is 0 otherwise loop continues forever.")
      (make-range from to step))))

(defmethod print-object ((obj Range) stream)
  (format stream
	  (if (numberp (pprint-range-size obj))
	      "<Range For ~a, [~a, ~a), step=~a>"
	      "<Range~%    For [~a]~%      from ~a~%      to ~a~%      stepby ~a>")	      
	  (pprint-range-size obj)
	  (symbol-pprint-helper (range-from obj))
	  (symbol-pprint-helper (range-to   obj))
	  (symbol-pprint-helper (range-step obj))))

(defun .range (range2 &optional (range1 nil))
  "
## [function] .range

```lisp
(range+ range2 &optional (range1 nil))
```

Interprets the value of range2 from a viewpoint of range1.

```
Applying further slicing:
    (Range 2 10 2) ;; range1
 +) (Range 0 4  2) ;; range2
 ------------------
    (Range 2 4 2)
```
"
  (declare (type Range range2)
	   (type (or null Range) range1))

  (when (null range1)
    ;; NIL(RANGE1...)
    (return-from .range range2))

  
  
  

  )

