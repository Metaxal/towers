#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require "game.rkt"
         "base.rkt"
         racket/class
         )

(define (write-game game [out (current-output-port)])
  (write (send game game->string) out)
  )

(define (string->game str)
  (read-game (open-input-string str)))

(define (read-game [in (current-input-port)])
  (list-game->game (read in)))

(define (save-game file game)
  (with-output-to-file file
    (λ()(display (send game game->string)))
    #:exists 'replace
    ))

(define (load-game file)
  (and (file-exists? file)
       (with-input-from-file file
         (λ()(read-game))
         )))

(define (save-current-game file) 
  (save-game file current-game))

(define (load-current-game file)
  (set-current-game (load-game file))
  )

#| Tests | #

(require "player.rkt" "player-ai1.rkt")
(define gstr 
  "(\"1.42\" () 1283266769 10 \"Player one\" \"AI-1: Player two\" \"player-human%\" \"player-ai1%\" (((move 4 8 4 5 1) (move 3 8 3 6 1) end) ((move 6 1 6 4 1) (move 6 0 6 3 1)) ((move 5 9 4 9 1) (move 3 9 3 8 1) (move 2 9 2 8 1) end) ((move 3 1 3 6 1) (move 6 4 7 4 1)) ()))")
(define g (string->game gstr))
(send g game->string)
;|#
