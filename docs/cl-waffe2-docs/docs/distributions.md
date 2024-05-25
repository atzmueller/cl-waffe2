
# Distributions

## Sampling matrices from distribution
cl-waffe2 provides a package `:cl-waffe2/distributions` which is used to sample matrices from the distributions.
## Common Format to the APIs
All sampling functions are defined in the following format via `define-tensor-initializer` macro.

```(function-name shape [Optional Arguments] &rest args &keys &allow-other-keys)```

That is, arguments passed to the `make-tensor` function can also be passed directly to the initializer functions.

### Example

```lisp
(normal `(10 10) 0.0 1.0 :requires-grad t)

{LISPTENSOR[float] :shape (10 10)  
  ((0.09241722   -1.8139324   0.33998385   ~ -1.7448716   -0.11915433  1.2616262)                    
   (0.034676224  0.31745166   0.8633344    ~ -0.14157301  -0.9596394   -0.52192944)   
                 ...
   (-0.018849093 0.10730301   0.7192831    ~ 0.7583118    1.3229972    -1.2871348)
   (-0.69942784  0.88236964   -0.6999107   ~ -0.3676781   -2.0036936   0.67751735))
  :facet :exist
  :requires-grad T
  :backward NIL}
```

### Example

```lisp
(ax+b `(10 10) 1 0 :dtype :uint8)

{LISPTENSOR[uint8] :shape (10 10)  
  ((0  1  2  ~ 7  8  9)          
   (10 11 12 ~ 17 18 19)   
       ...
   (80 81 82 ~ 87 88 89)
   (90 91 92 ~ 97 98 99))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## define-tensor-initializer
```lisp
(define-tensor-initializer (function-name (&rest args) initializer-lambda document &key (keep-order? nil)))
```


`define-tensor-initializer` is a macro which is used to define a initializer function.


Initializer function is a function whose arguments follow this format:

    (function-name shape <Initializer's Arguments> &rest initargs &key &allow-other-keys)

Input:

    function-name - the function is defined after this argument

    args          - Initializer's Arguments

    initializer-lambda - A form to be expanded as the sampling function, which must return a function of #'(lambda (i) ...) where i is the index of element.

    keep-order? - set t if the index is needed to sampling matrices.

Example:

```lisp
(define-initializer-function
    uniform-random
    (upfrom below)
  (let ((upfrom (coerce upfrom (dtype->lisp-type (dtype tensor))))
	(below  (coerce below  (dtype->lisp-type (dtype tensor)))))
    #'(lambda (i)
	(declare (ignore i))
	(sample-uniform-random upfrom below)))
    "")

(uniform-random `(10 10) 0.1 0.3 :requires-grad t)

{CPUTENSOR[float] :shape (10 10)  
  ((0.13149574  0.15135926  0.1569588   ~ 0.103781514 0.20610212  0.19365484)                   
   (0.2638953   0.12672275  0.21630599  ~ 0.16542184  0.10228193  0.12928057)   
                ...
   (0.20429519  0.12252951  0.17538154  ~ 0.22072719  0.18642941  0.11027551)
   (0.14372297  0.11097031  0.25514898  ~ 0.28739202  0.18398522  0.15176433))
  :facet :exist
  :requires-grad T
  :backward NIL}
```

(Note that new tensor is binded to tensor, being used to determined dtype etc...)

## ax+b

```lisp
(ax+b shape a b &rest initargs &key &allow-other-keys)
```

The function ax+b is a family of initializer functions, and samples matrices from arithmetic progression.

```math
out_n = an + b
```

Inputs:

    a, b - Coefficients of the above formula.
### Example

```lisp
(ax+b `(3 3) 1.0 0.0)

{LISPTENSOR[float] :shape (3 3)  
  ((0.0 1.0 2.0)
   (3.0 4.0 5.0)
   (6.0 7.0 8.0))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## beta

```lisp
(beta shape alpha beta &rest initargs &key &allow-other-keys)
```


The function beta is a family of initializer functions, and sample matrices from beta distribution.

### Reference

1. Generating Beta Variates with Nonintegral Shape Parameters (R. C. H. Cheng University of Wales Institute of Science and Technology)


2. https://dl.acm.org/doi/pdf/10.1145/359460.359482


Note: My implementation is unstable, being occurs floating-overflow constantly..., especially when min(alpha, beta) < 1.0 (i.e.: beta-bc)
### Example

```lisp
(beta `(3 3) 5.0 1.0)

{LISPTENSOR[float] :shape (3 3)  
  ((0.76956904 0.8549012  0.4545031)
   (0.914095   0.54855245 0.93831366)
   (0.7510813  0.45294034 0.9096131))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## bernoulli

```lisp
(bernoulli shape p &rest initargs &key &allow-other-keys)
```
The bernoulli is a family of initializer functions, and samples matrices from bernoulli distribution.

### Inputs

p - Takes 1 with probability p and 0 with probalibity (1-p).
### Example

```lisp
(bernoulli `(3 3) 0.3)

{LISPTENSOR[float] :shape (3 3)  
  ((0.0 1.0 0.0)
   (0.0 0.0 0.0)
   (0.0 0.0 0.0))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## chisquare

```lisp
(chisquare shape df &rest initargs &key &allow-other-keys)
```
The function chisquare is a family of initializer functions, and samples matrices from chisquare distributions.

### Inputs

df - degree of freedom.

### References

 https://github.com/lvaruzza/cl-randist
### Example

```lisp
(chisquare `(3 3) 1.0)

{LISPTENSOR[float] :shape (3 3)  
  ((0.4950697    1.3176446    0.97631454)
   (0.17928894   0.7067763    0.06370751)
   (0.0054754415 0.1824935    1.639507))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## exponential

```lisp
(exponential shape &rest initargs &key &allow-other-keys)
```
The function exponential is a family of initializer functions, and samples the exponential distribution using ziggurat algorithm with table-size=256.


### References

1. https://andantesoft.hatenablog.com/entry/2023/04/30/183032

2. Marsaglia, G., & Tsang, W. W. (2000). The ziggurat method for generating random variables. Journal of statistical software.

3. https://marui.hatenablog.com/entry/2023/01/23/194507
### Example

```lisp
(exponential `(3 3))

{LISPTENSOR[float] :shape (3 3)  
  ((1.1214623   2.3461883   0.6938687)
   (0.08668403  0.46339378  0.18236026)
   (0.074848704 2.148749    1.5031147))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## gamma

```lisp
(gamma shape k &rest initargs &key &allow-other-keys)
```
The function gamma is a family of initializer functions, and samples matrices from the gamma distribution.

### References

1. https://github.com/lvaruzza/cl-randist

### Example

```lisp
(gamma `(3 3) 1.0)

{LISPTENSOR[float] :shape (3 3)  
  ((0.20066561  1.0735147   1.0844046)
   (0.115611516 2.299866    0.2878098)
   (3.3350327   0.7665806   0.8527828))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## normal

```lisp
(normal shape mean stddev &rest initargs &key &allow-other-keys)
```
The function normal is a family of initializer functions, and samples matrices from normal distribution.


### Reference

1. https://github.com/lvaruzza/cl-randist (seems to create ziggurat table with size=128)


### Inputs

mean

stddev - Standard Deviation, σ.

### Example

```lisp
(normal `(3 3) 1.0 0.0)

{LISPTENSOR[float] :shape (3 3)  
  ((1.0 1.0 1.0)
   (1.0 1.0 1.0)
   (1.0 1.0 1.0))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## uniform-random

```lisp
(uniform-random shape upfrom below &rest initargs &key &allow-other-keys)
```
The function uniform-random is a family of initializer functions, and samples matrices from uniform random distribution using Common Lisp's standard function, `(random arg)`.

Input:

    upfrom, below. Each elements of returned tensor is in the range of: `[upfrom, below)`
### Example

```lisp
(uniform-random `(3 3) 2 4)

{LISPTENSOR[float] :shape (3 3)  
  ((2.3659306 2.2203517 2.9010468)
   (2.0084918 2.673732  2.288423)
   (2.6262066 3.993234  3.0970056))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```

## randn

```lisp
(randn shape &rest initargs &key &allow-other-keys)
```
The function randn is a family of initializer functions, and samples the gaussian distributions using ziggurat algorithm with table-size=256.


### References


1. https://andantesoft.hatenablog.com/entry/2023/04/30/183032

2. Marsaglia, G., & Tsang, W. W. (2000). The ziggurat method for generating random variables. Journal of statistical software.

3. https://marui.hatenablog.com/entry/2023/01/23/194507
### Example

```lisp
(randn `(3 3))

{LISPTENSOR[float] :shape (3 3)  
  ((1.6019585    -0.715621    -0.015199781)
   (-0.3570089   0.028855132  -0.67624414)
   (0.003321576  0.093405314  0.43108767))
  :facet :exist
  :requires-grad NIL
  :backward NIL}
```
