#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require bazaar/string
         bazaar/preferences
         racket/class
         racket/tcp
         )

(define current-version  "1.54")
(define game-min-version "1.50") ; games below this number cannot be read

;; Comparison of 2 users
;; Case insentitive, + type check (string?)
(define user=? string?-ci=?)

(define game<%> (interface ())) ; just to be used for contracts

(define prefs 
  (new preferences% [file (make-config-file-path "towers" "prefs.rktd")]
       [default-preferences
         '((server-address    . "localhost")
           (server-root-path  . "towers")
           (server-port       . 8080)
           (server-version    . "2.0")
           (user              . #f)
           (password          . #f)
           )]))

(define pref-file
  (case-lambda
    [() (send prefs get-file)]
    [(file) (send prefs set-file file)]))

;; Make accessors
;; (warning: uses the value of prefs at the time of the definition, so we can't change 
;; the prefs binding afterwards.)
(define-pref-procs prefs
  (server-address    'server-address)
  (server-root-path  'server-root-path)
  (server-port       'server-port)
  (server-version    'server-version)
  (current-user      'user)
  (current-password  'password)
  )

;; If file is a path-string?, it is used as the new preference file onwards
(define (load-preferences [file #t])
  (when file
    (unless (eq? file #t)
      (pref-file file))
    (send prefs load (pref-file))))
