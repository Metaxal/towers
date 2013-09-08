#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require racket/file
         racket/dict
         racket/contract
         racket/runtime-path
         (for-syntax mzlib/os racket/base)
         mzlib/os)

(provide read-preferences get-pref set-pref pref-file)

;; The default preference file is 
;; named after the username and the machine name.
(define-runtime-path default-pref-file 
  (build-path 'up "configs" 
              (string-append (or (getenv "USER") "") "@" (gethostname) ".rktd")))
; ex: ../configs/laurent@home.rktd

(define pref-file (make-parameter default-pref-file))

(define preferences '()) ; Not a parameter, therefore global

;; If file is a path-string?, this file is used to read the preferences.
;; If file is #t, then pref-file is used as the preference file.
;; If file is #f, the preferences are not read.
(define/contract (read-preferences [file #t])
  ([] [(or/c #f #t path-string?)] . ->* . any)
  (when file (set! preferences (file->value (if (eq? file #t) (pref-file) file)))))

(define (get-pref sym [default (λ()(error "Preference not found: " sym))])
  (dict-ref preferences sym default))

;; Modifies the current preferences, but does not write it to disk
(define (set-pref sym value)
  (set! preferences
        (dict-set preferences sym value)))
