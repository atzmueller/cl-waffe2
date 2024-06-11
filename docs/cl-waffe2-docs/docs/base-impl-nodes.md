
# Standard Nodes

## [node] ADDNODE

```
(A[~] B[~] -> A[~])
```

### Description

`AddNode` is a node which computes following operation element-wise.

Let X and Y be a given arguments and both are matrix.

```math
X\gets{X + Y}
```

### Constructor

```
(AddNode dtype)
```

`dtype` dtype to use, being used to dispatch backends. (e.g.: `:float` `:uint8`)



### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dx dy)) (values dout dout))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SUBNODE

```
(A[~] B[~] -> A[~])
```

### Description

`SubNode` is a node which computes following operation element-wise.

Let X and Y be a given arguments and both are matrix.

```math
X\gets{X - Y}
```

### Constructor

```
(SubNode dtype)
```

`dtype` dtype to use, being used to dispatch backends. (e.g.: `:float` `:uint8`)



### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dx dy)) (values dout (!mul -1 dout)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] MULNODE

```
(A[~] B[~] -> A[~])
```

### Description

`MulNode` is a node which computes following operation element-wise.

Let X and Y be a given arguments and both are matrix.

```math
X\gets{X * Y}
```

### Constructor

```
(MulNode dtype)
```

`dtype` dtype to use, being used to dispatch backends. (e.g.: `:float` `:uint8`)



### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (values (!mul dout dy) (!mul dout dx)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] DIVNODE

```
(A[~] B[~] -> A[~])
```

### Description

`DivNode` is a node which computes following operation element-wise.

Let X and Y be a given arguments and both are matrix.

```math
X\gets{X / Y}
```

### Constructor

```
(DivNode dtype)
```

`dtype` dtype to use, being used to dispatch backends. (e.g.: `:float` `:uint8`)



### Backward

✅ Already defined. 

```lisp
((self dout dx dy)
 (values (!div dout dy) (!div (!mul (!mul dout -1) dx) (!mul dy dy))))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] MOVETENSORNODE

```
(A[~] B[~] -> A[~])
```

### Description


Moves all the visible elements of `B` into visible areas of `A`.

```math
A\gets{B}
```

### Constructor

`(MoveTensorNode dtype)`

`dtype` dtype to use.



### Backward

✅ Already defined. 

```lisp
((self dout dx dy)
 (let ((dy-out
        (if (and (eql (tensor-attribute dy) chain) (movetensor-ignore-me self))
            dout
            (if (tensor-permuted-p dout)
                (let ((out
                       (make-input (shape dx) nil create-from dout dtype
                                   (dtype dx) order (order dx))))
                  (!move out dout force t))
                (!copy dout force t)))))
   (values nil dy-out)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ABSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ABSNODE` takes X as an argument, applying a abs function into each element and writes the result into out.

```math
OUT\gets{abs(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-ABSNODE` `!abs`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dy)) (values (!mul dout (!sign dx)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-ABSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ABSNODE takes scalar X as an argument, applying a abs function into each element and writes the result into out.

```math
out\gets{abs(x)}
```
save-for-backward: (T NIL)

See also: `ABSNODE` `!abs`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dy)) (values (!mul dout (!sign dx)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SIGNNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `SIGNNODE` takes X as an argument, applying a sign function into each element and writes the result into out.

```math
OUT\gets{sign(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-SIGNNODE` `!sign`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dout dy)) (values (!mul dx 0) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-SIGNNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-SIGNNODE takes scalar X as an argument, applying a sign function into each element and writes the result into out.

```math
out\gets{sign(x)}
```
save-for-backward: (T NIL)

See also: `SIGNNODE` `!sign`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dout dy)) (values (!mul dx 0) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SQRTNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `SQRTNODE` takes X as an argument, applying a sqrt function into each element and writes the result into out.

```math
OUT\gets{sqrt(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-SQRTNODE` `!sqrt`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dy)) (values (!mul dout (!div 1 dx)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-SQRTNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-SQRTNODE takes scalar X as an argument, applying a sqrt function into each element and writes the result into out.

```math
out\gets{sqrt(x)}
```
save-for-backward: (T NIL)

See also: `SQRTNODE` `!sqrt`

### Backward

✅ Already defined. 

```lisp
((self dout dx dy) (declare (ignore dy)) (values (!mul dout (!div 1 dx)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SQUARENODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `SQUARENODE` takes X as an argument, applying a square function into each element and writes the result into out.

```math
OUT\gets{square(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-SQUARENODE` `!square`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout x) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-SQUARENODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-SQUARENODE takes scalar X as an argument, applying a square function into each element and writes the result into out.

```math
out\gets{square(x)}
```
save-for-backward: (T NIL)

See also: `SQUARENODE` `!square`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout x) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SINNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `SINNODE` takes X as an argument, applying a sin function into each element and writes the result into out.

```math
OUT\gets{sin(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-SINNODE` `!sin`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!cos x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-SINNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-SINNODE takes scalar X as an argument, applying a sin function into each element and writes the result into out.

```math
out\gets{sin(x)}
```
save-for-backward: (T NIL)

See also: `SINNODE` `!sin`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!cos x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] COSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `COSNODE` takes X as an argument, applying a cos function into each element and writes the result into out.

```math
OUT\gets{cos(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-COSNODE` `!cos`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!mul -1 (!sin x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-COSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-COSNODE takes scalar X as an argument, applying a cos function into each element and writes the result into out.

```math
out\gets{cos(x)}
```
save-for-backward: (T NIL)

See also: `COSNODE` `!cos`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!mul -1 (!sin x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] TANNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `TANNODE` takes X as an argument, applying a tan function into each element and writes the result into out.

```math
OUT\gets{tan(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-TANNODE` `!tan`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul (!cos x) (!cos x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-TANNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-TANNODE takes scalar X as an argument, applying a tan function into each element and writes the result into out.

```math
out\gets{tan(x)}
```
save-for-backward: (T NIL)

See also: `TANNODE` `!tan`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul (!cos x) (!cos x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ASINNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ASINNODE` takes X as an argument, applying a asin function into each element and writes the result into out.

```math
OUT\gets{asin(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-ASINNODE` `!asin`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!sqrt (!sub 1 (!square x))))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-ASINNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ASINNODE takes scalar X as an argument, applying a asin function into each element and writes the result into out.

```math
out\gets{asin(x)}
```
save-for-backward: (T NIL)

See also: `ASINNODE` `!asin`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!sqrt (!sub 1 (!square x))))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ACOSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ACOSNODE` takes X as an argument, applying a acos function into each element and writes the result into out.

```math
OUT\gets{acos(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-ACOSNODE` `!acos`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div -1 (!sqrt (!sub 1 (!square x))))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-ACOSNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ACOSNODE takes scalar X as an argument, applying a acos function into each element and writes the result into out.

```math
out\gets{acos(x)}
```
save-for-backward: (T NIL)

See also: `ACOSNODE` `!acos`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div -1 (!sqrt (!sub 1 (!square x))))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ATANNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ATANNODE` takes X as an argument, applying a atan function into each element and writes the result into out.

```math
OUT\gets{atan(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-ATANNODE` `!atan`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!add 1 (!square x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-ATANNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ATANNODE takes scalar X as an argument, applying a atan function into each element and writes the result into out.

```math
out\gets{atan(x)}
```
save-for-backward: (T NIL)

See also: `ATANNODE` `!atan`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!add 1 (!square x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SINHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `SINHNODE` takes X as an argument, applying a sinh function into each element and writes the result into out.

```math
OUT\gets{sinh(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-SINHNODE` `!sinh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!cosh x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-SINHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-SINHNODE takes scalar X as an argument, applying a sinh function into each element and writes the result into out.

```math
out\gets{sinh(x)}
```
save-for-backward: (T NIL)

See also: `SINHNODE` `!sinh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!cosh x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] COSHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `COSHNODE` takes X as an argument, applying a cosh function into each element and writes the result into out.

```math
OUT\gets{cosh(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-COSHNODE` `!cosh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!mul -1 (!sinh x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-COSHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-COSHNODE takes scalar X as an argument, applying a cosh function into each element and writes the result into out.

```math
out\gets{cosh(x)}
```
save-for-backward: (T NIL)

See also: `COSHNODE` `!cosh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!mul -1 (!sinh x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] TANHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `TANHNODE` takes X as an argument, applying a tanh function into each element and writes the result into out.

```math
OUT\gets{tanh(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-TANHNODE` `!tanh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul (!cosh x) (!cosh x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-TANHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-TANHNODE takes scalar X as an argument, applying a tanh function into each element and writes the result into out.

```math
out\gets{tanh(x)}
```
save-for-backward: (T NIL)

See also: `TANHNODE` `!tanh`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul (!cosh x) (!cosh x)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ASINHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ASINHNODE` takes X as an argument, applying a asinh function into each element and writes the result into out.

```math
OUT\gets{asinh(X)}
```

save-for-backward: NIL

See also: `SCALAR-ASINHNODE` `!asinh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] SCALAR-ASINHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ASINHNODE takes scalar X as an argument, applying a asinh function into each element and writes the result into out.

```math
out\gets{asinh(x)}
```
save-for-backward: NIL

See also: `ASINHNODE` `!asinh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] ACOSHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ACOSHNODE` takes X as an argument, applying a acosh function into each element and writes the result into out.

```math
OUT\gets{acosh(X)}
```

save-for-backward: NIL

See also: `SCALAR-ACOSHNODE` `!acosh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] SCALAR-ACOSHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ACOSHNODE takes scalar X as an argument, applying a acosh function into each element and writes the result into out.

```math
out\gets{acosh(x)}
```
save-for-backward: NIL

See also: `ACOSHNODE` `!acosh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] ATANHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `ATANHNODE` takes X as an argument, applying a atanh function into each element and writes the result into out.

```math
OUT\gets{atanh(X)}
```

save-for-backward: NIL

See also: `SCALAR-ATANHNODE` `!atanh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] SCALAR-ATANHNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-ATANHNODE takes scalar X as an argument, applying a atanh function into each element and writes the result into out.

```math
out\gets{atanh(x)}
```
save-for-backward: NIL

See also: `ATANHNODE` `!atanh`

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] EXPNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `EXPNODE` takes X as an argument, applying a exp function into each element and writes the result into out.

```math
OUT\gets{exp(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-EXPNODE` `!exp`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!exp x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-EXPNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-EXPNODE takes scalar X as an argument, applying a exp function into each element and writes the result into out.

```math
out\gets{exp(x)}
```
save-for-backward: (T NIL)

See also: `EXPNODE` `!exp`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!exp x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LOG2NODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `LOG2NODE` takes X as an argument, applying a log2 function into each element and writes the result into out.

```math
OUT\gets{log2(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-LOG2NODE` `!log2`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul x (log 2)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-LOG2NODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-LOG2NODE takes scalar X as an argument, applying a log2 function into each element and writes the result into out.

```math
out\gets{log2(x)}
```
save-for-backward: (T NIL)

See also: `LOG2NODE` `!log2`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul x (log 2)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LOG10NODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `LOG10NODE` takes X as an argument, applying a log10 function into each element and writes the result into out.

```math
OUT\gets{log10(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-LOG10NODE` `!log10`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul x (log 10)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-LOG10NODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-LOG10NODE takes scalar X as an argument, applying a log10 function into each element and writes the result into out.

```math
out\gets{log10(x)}
```
save-for-backward: (T NIL)

See also: `LOG10NODE` `!log10`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!mul x (log 10)))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LOGENODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `LOGENODE` takes X as an argument, applying a loge function into each element and writes the result into out.

```math
OUT\gets{loge(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-LOGENODE` `!loge`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!div 1 x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-LOGENODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-LOGENODE takes scalar X as an argument, applying a loge function into each element and writes the result into out.

```math
out\gets{loge(x)}
```
save-for-backward: (T NIL)

See also: `LOGENODE` `!loge`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out)) (values (!mul dout (!div 1 x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LOG1PNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node `LOG1PNODE` takes X as an argument, applying a log1p function into each element and writes the result into out.

```math
OUT\gets{log1p(X)}
```

save-for-backward: (T NIL)

See also: `SCALAR-LOG1PNODE` `!log1p`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!add 1 x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] SCALAR-LOG1PNODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description

The node SCALAR-LOG1PNODE takes scalar X as an argument, applying a log1p function into each element and writes the result into out.

```math
out\gets{log1p(x)}
```
save-for-backward: (T NIL)

See also: `LOG1PNODE` `!log1p`

### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (values (!mul dout (!div 1 (!add 1 x))) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LAZYTRANSPOSENODE

```
(A[~ I J] -> A[~ I J])
```

### Description

LazyTransposeNode is a matmul-dedicated node to implement zero-cost transpose.

The node stores untransposed tensor at `raw-tensor`, when expanding matmul form, you can read it if needed.

### Backward

✅ Already defined. 

```lisp
((self dout dx) (declare (ignore dx)) (values dout))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ARGMAX-NODE

```
(A[~] OUT[OUT-SIZE] -> OUT[OUT-SIZE])
```

### Description

ArgMax-Node finds an index of maximum value of all elements in A. `OUT` is overwritten with the result.

A is a target to find a maximum value, and OUT is a place to set the index.

### Constructor

```
(ArgMax-Node out-size)
```

`out-size` the reducted shape of `out`.


### Backward

✅ Already defined. 

```lisp
((self dout da do) (declare (ignore dout da do)) (values nil nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] ARGMIN-NODE

```
(A[~] OUT[OUT-SIZE] -> OUT[OUT-SIZE])
```

### Description

ArgMin-Node finds an index of minimum value of all elements in A. `OUT` is overwritten with the result.

A is a target to find a minimum value, and OUT is a place to set the index.

### Constructor

```
(ArgMin-Node out-size)
```

`out-size` the reducted shape of `out`.

### Backward

✅ Already defined. 

```lisp
((self dout da do) (declare (ignore dout da do)) (values nil nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] MAXVALUE-NODE

```
(A[~] OUT[OUT-SIZE] -> OUT[OUT-SIZE])
```

### Description

MaxValue-Node finds a maximum value of all elements in A. `OUT` is overwritten with the result.

A is a target to find a maximum value, and OUT is a place to set the index.

### Constructor

```
(MaxValue-Node out-size)
```

`out-size` the reducted shape of `out`.


### Backward

✅ Already defined. 

```lisp
((self dout da do) (declare (ignore do))
 (let ((mask (a=b da (!view (!max da) (broadcast-to da)))))
   (values (!mul mask (!view dout (broadcast-to mask))) nil)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] MINVALUE-NODE

```
(A[~] OUT[OUT-SIZE] -> OUT[OUT-SIZE])
```

### Description

MinValue-Node finds a minimum value of all elements in A. `OUT` is overwritten with the result.

A is a target to find a minimum value, and OUT is a place to set the index.

### Constructor

```
(MinValue-Node out-size)
```

`out-size` the reducted shape of `out`.

### Backward

✅ Already defined. 

```lisp
((self dout da do) (declare (ignore do))
 (let ((mask (a=b da (!view (!min da) (broadcast-to da)))))
   (values (!mul mask (!view dout (broadcast-to mask))) nil)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] MATMULNODE

```
(A[~ I J] B[~ J K] C[~ I K] -> C[~ I K])
```

### Description

MatmulNode Computes a matrix multiplication of given A and B, set the result to C.

```math
C\gets{gemm(1.0, A, B, 0.0, C)}
```

### Constructor

```
(MatMulNode dtype &key transpose-a transpose-b)
```

`dtype` dtype to use.

`transpose-a transpose-b[boolean]` becomes t if the given `a` or `b` needs to be transposed respectively. call `(read-untransposed tensor)` to read untransposed tensor.



### Backward

✅ Already defined. 

```lisp
((self dout da db do) (declare (ignore do))
 (values (!matmul dout (!t db)) (!matmul (!t da) dout) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LAZY-FUNCTION-NODE

```
(X[~] OUT[~] -> OUT[~])
```

### Description


An abstract computation node that dynamically compile the given kernel specified by `forward` with a loop, applying it to X and OUT element-wise. A backend `LispTensor` already provides a standard implementation of it and can be used by the `(cl-waffe2/base-impl:lazy ...)` function. This node is useful when calling mathematical functions not provided by cl-waffe2 as standard; (Note that no speed improvement can be expected from SIMD.)

```lisp
;; Example:
(lazy #'sin (randn `(3 3)) :diff #'cos)
```

### Inputs

- `forward[symbol or function]` indicates a name of function of forward propagation. the function must receive a single argument of corresponding element.

- `backward[symbol or function]` indicates a name of function of backward propagation. As the backward definition indicates, the gradient of the previous node is automatically combined by Lazy-Function-Node. therefore, #'cos is enough for example.

- `sv4bw[boolean]` set T to copy the result of X.

### Workload

- [x] implement
- [x] make it differentiable
- [x] compiled kernels are cached in LUT.
- [ ] parallelize by lparallel
- [ ] Loop Collapse/Reordering


### Backward

✅ Already defined. 

```lisp
((self dout x out) (declare (ignore out))
 (when (null (backward-of self))
   (error
    lazy: in order to differentiate the lazy operation ~a, specify :backward.
(lazy op tensor ... :diff nil)
                           l specify this form.
    (forward-of self)))
 (values (!mul dout (lazy (backward-of self) x)) nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] LAZY-REDUCE-NODE

```
(REDUCED[~ REDUCED] X[~ DIM] -> REDUCED[~ REDUCED])
```

### Description


As well as `Lazy-Function-Node`, this node dynamically compiles the given kernel specified by `forward` with a loop, applying it to X and OUT element-wise. The only difference is that the last dimension of returned tensor is reduced to `reduced`. The kernel function `forward` wil receive all elements of the last dimension of `X`, and selects from it and return `reduced` values. (Note that the value is returned by `(apply #'values list)`, NOT A LIST.)

See the example of `lazy-reduce`.

As of this writing, this node isn't differentiable.

### Workload

- [x] implement
- [ ] make it differentiable
- [ ] caching
- [ ] parallelize by lparallel
- [ ] loop oriented optimizations


### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)
## [node] WHERE-OPERATION-NODE

```
(A[~] OUT[~] -> OUT[~])
```

### Description

Where-Operation-Node is a node which set `true-then`, if the result of calling `condition` with each element of A, is t and if it is NIL, set `false-then` at corresponding position.

### Constructor

```
(Where-Operation-Node condition true-then false-then)
```

`true-then` and `false-then` is a number.

`condition` a single argument function, each element of A is argument. (e.g.: this could be `#'evenp` `#'oddp` etc...)


### Backward

✅ Already defined. 

```lisp
((self dout da do) (declare (ignore dout da do)) (values nil nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] COMPARE-OPERATION-NODE

```
(A[~] B[~] OUT[~] -> OUT[~])
```

### Description

Compare-Operation-Node is a node which set `true-then`, if the result of calling `condition` with each element of A and B, if it is NIl set `false-then` at corresponding position.

### Constructor

```
(Compare-Operation-Node condition true-then false-then)
```

`true-then` and `false-then` is a number.

`condition` a two arguments function, each element of A and B is argument. (e.g.: this could be `#'>` or `#'<` etc...)


### Backward

✅ Already defined. 

```lisp
((self dout da db do) (declare (ignore dout da db do)) (values nil nil nil))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] IM2COLNODE

```
(X[N C H W] COL[N C K-H K-W H-OUT W-OUT] -> COL[N C K-H K-W H-OUT W-OUT])
```

### Description

Im2ColNode is `AbstractNode` which implements forward propagation of [nn.Unfold](https://pytorch.org/docs/stable/generated/torch.nn.Unfold.html).

The node is only executed through the `cl-waffe2/nn:unfold` function, so arguments for constructors are dispatched automatically. In addition, the tensor `X` it receive will be the one after padding has been performed.

### Slots

`N` indicates the number of batch-size

`C` indicates a channel-size

`k-h`, `k-w` represents the size of kernel. height and width respectively.

`h-out` `w-out` is the size of output weight.

`stride-w stride-h` is the number of strides.

`padding-w padding-h dilation-w dilation-h` more parameters.

`img-out[AbstractTensor]` allocated area to set the result, being accessed by `(img-out-of self)` .

All symbols are exported from `cl-waffe2/base-impl` package and `with-slots` is useful to read all slots.

In order to implement device-specific implementation of `Unfold`, do define-impl for both `Im2ColNode` and `Col2ImNode`.


### Backward

✅ Already defined. 

```lisp
((self dout x col) (declare (ignore col))
 (setf (h-of self) (nth 2 (shape x))
       (w-of self) (nth 3 (shape x)))
 (with-slots ((n n) (c c) (h h) (w w) (h-out h-out) (w-out w-out) (k-h k-h)
              (k-w k-w) (padding-h padding-h) (padding-w padding-w)
              (dilation-h dilation-h) (dilation-w dilation-w)
              (stride-h stride-h) (stride-w stride-w))
     self
   (values
    (call
     (col2imnode n c k-h k-w h-out w-out stride-h stride-w padding-h padding-w
      dilation-h dilation-w (img-out-of self) h h w w)
     dout (img-out-of self))
    nil)))
```

No need to implement backwards at `define-impl`. (they'd be ignored.)
## [node] COL2IMNODE

```
(COL[N C K-H K-W H-OUT W-OUT] X[N C H W] -> X[N C H W])
```

### Description

Col2ImNode is `AbstractNode` which implements backward propagation of [nn.Unfold](https://pytorch.org/docs/stable/generated/torch.nn.Unfold.html). It has completely the same slots and arguments to `Im2Col`.

See also: `Im2ColNode` documentation for argument descriptions.

### Backward

❌ Undefined. (To make it differentiable, must be defined with `define-impl` macro.)