#lang racket

(define atom?
  (lambda (a)
    (cond
      ((null? a) #f)
      ((pair? a) #f)
      (else #t)
    )
  )
)

(define lat?
  (lambda (l)
    (cond
      ((null? l) #t)
      ((atom? (car l)) (lat? (cdr l)))
      (else #f)
    )
  )
)

(define member?
  (lambda (l e)
    (cond
      ((null? l) #f)  
      ((eq? (car l) e) #t)
      (else (member? (cdr l) e))
    )
  )
)

(define remove
  (lambda (l e)
    (cond
      ((null? l) '())  
      ((eq? (car l) e) (cdr l))
      (else (cons (car l) (remove (cdr l) e)))
    )
  )
)

(define wlen
  (lambda (lst) 
    (if (null? lst)
      0
      (+ 1 (wlen (cdr lst)))
    )
  )
)

(define wnth
  (lambda (lst n)
    (cond
      ((>= n (wlen lst)) '())
      ((eq? n 0) (car lst))
      (else (wnth (cdr lst) (- n 1)))
    )
  )
)

(define lst '(a b b c))
(eq? '(a b c) '(a b c))
(atom? 's)
(atom? '())
(atom? (car lst))
'lat
(lat? lst)
(lat? '())
(lat? '(() () ()))
(lat? '(a b c))
(lat? '((a) b c))
(lat? '(a (b) c))
(lat? '(a b ()))
(lat? '(a b (a b)))
(wlen lst)
(wnth lst 0)
(wnth lst 1)
(wnth lst 2)
(wnth lst 3)
'member
(member? lst 'a)
(member? lst 'b)
(member? lst 'c)
(member? lst 'd)
'remove
(remove lst 'a)
(remove lst 'b)
(remove lst 'c)
(remove lst 'd)