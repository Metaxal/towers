#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require bazaar/string
         bazaar/preferences
         bazaar/getter-setter
         racket/class
         racket/tcp
         )

(define current-version  "2.0")
(define game-min-version "2.0") ; games below this number cannot be read

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

(define/m-setter list-game->game #f) ; stub. Defined in game.rkt, used also in connection.rkt

;=============================;
;=== Debugging and logging ===;
;=============================;

(define-logger towers-lib)

; Display the game in the logger
(define (debug-game g)
  (log-debug (string-append "\n" (send g ->string))))

(define (loop-receive . receivers)
  (void
   (thread
    (λ()(let loop ()
          (define v (apply sync receivers))
          (printf "~a [~a]\n" (vector-ref v 1) (vector-ref v 0))
          (loop))))))

(define no-logger (make-logger 'no-logger))
(define-syntax-rule (without-logger body ...)
  (parameterize ([current-logger no-logger])
    body ...))

;; Returns the result of the expression,
;; but if the expression is #f, has the side effect
;; of logging a message
(define (or-log expr str . args)
  (cond [expr]
        [else
         (log-message (current-logger)
                      'debug
                      (if (null? args)
                          str
                          (apply format str args))
                      #f)
         #f]))
