#lang racket
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require towers-lib/base
         towers-lib/game ; to set list-game->game
         towers-lib/player
         towers-lib/player-alpha-beta
         bazaar/rackunit
         ;profile ; useless here?!
         )

(current-logger towers-lib-logger)
(define tll-rc (make-log-receiver towers-lib-logger 'debug))
(define ab-rc  (make-log-receiver alpha-beta-logger 'debug))
(loop-receive #;tll-rc ab-rc)

(load-preferences)

#;(let ()
  (define g1 (list-game->game lg1))
  (send g1 replay-game)
  ;(debug-game g1)
  (send g1 display-text)
  (define pl1 (send g1 get-player1))
  (send pl1 set-depth-max 1)
  
  (check-equal? (send pl1 master-attacked?)
                '((2 4) (1 4)))
  (send g1 play-move '(move 3 4 2 4 1))
  (check-false (send pl1 master-attacked?))
  )

#;(let ([g1 (list-game->game (file->value "master-reachable.twr"))])
  (send g1 replay-game)
  ;(debug-game g1)
  (send g1 display-text)
  (define pl1 (send g1 get-player1))
  (send pl1 set-ply-depth-max 1)
  (let-values ([(ply v) (send pl1 find-best-ply)])
    (check-equal? ply '((move 3 4 2 4 1))))
  )

; DOES NOT WORK YET!
(let ([g1 (list-game->game (file->value "master-reachable2.twr"))])
  (send g1 replay-game)
  ;(debug-game g1)
  (send g1 display-text)
  (define pl2 (send g1 get-player2))
  (displayln (send pl2 find-valid-1moves))
  (send pl2 set-ply-depth-max #;2 3)
  (time (send pl2 find-best-ply))
  #;(printf "nb-move-searched: ~a\n" (send pl2 get-nb-move-searched))
  )

; Test case for computation time
#;(let ([g1 (list-game->game (file->value "alpha-beta1.twr"))])
  (send g1 replay-game)
  ;(debug-game g1)
  (send g1 display-text)
  (define pl2 (send g1 get-player2))
  (displayln (send pl2 find-valid-1moves))
  (send pl2 set-ply-depth-max 2)
  (time (send pl2 find-best-ply))
  (printf "nb-move-searched: ~a\n" (send pl2 get-nb-move-searched))
  )

