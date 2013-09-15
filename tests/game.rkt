#lang racket
(require towers-lib/base
         towers-lib/game
         towers-lib/player
         towers-lib/connection
         bazaar/rackunit
         )

(current-logger towers-lib-logger)
(define tll-rc (make-log-receiver towers-lib-logger 'debug))
#;(loop-receive tll-rc)


(load-preferences)

; `let's to ensure that variables are not from a different context
(let ()
  (define lg1 (file->value "game1.twr"))
  (define g1 (list-game->game lg1))
  (send g1 replay-game)
  (check-equal? (send g1 game->list) lg1)
  (debug-game g1)
  )

(let ()
  (define g2 (new game% [nb-cells 5] [player1-class "Human"] [player2-class "Human"]
                  [player1-name "Moi"] [player2-name "Toi"]))

  (check-equal? (send g2 get-name1) "Moi")
  (check-equal? (send g2 get-name2) "Toi")
  (check-equal? (send g2 get-current-name) "Moi")
  (log-debug (~s (send g2 game->list)))

  (debug-game g2)
  (log-debug (send g2 get-current-name))
  (define mv1 '(move 0 3 0 2 1))
  (define mv1b '(move 0 2 0 1 #f))
  (define mv2 '(move 0 1 0 2 1))
  (check-false (send g2 play-move mv2 #:test? #t)) ; not allowed
  (send g2 play-move mv2) ; should not do anything
  (check-equal? (send g2 get-plies) '(()))
  (debug-game g2)

  (check-equal? (send g2 play-move mv1 #:test? #t) 1)
  (check-false (send g2 play-move mv1b #:test? #t))
  (check-not-fail (send g2 play-move mv1))
  (check-equal? (send g2 get-plies) (list (list mv1)))
  (check-false (send g2 play-move mv1 #:test? #t))  ; not allowed
  (check-false (send g2 play-move mv1b #:test? #t))
  (send g2 play-move mv1) ; should not change
  (check-equal? (send g2 get-plies) (list (list mv1)))
  (debug-game g2)

  (send g2 get-current-name)
  (check-false (send g2 play-move mv2 #:test? #t)) ; not allowed
  (send g2 play-move 'end) ; next player
  (check-equal? (send g2 get-plies) (list (list mv1) '()))
  (check-equal? (send g2 play-move mv2 #:test? #t) 1)
  (send g2 play-move mv2) ; ok, now allowed
  (check-equal? (send g2 get-plies) (list (list mv1) (list mv2)))
  (debug-game g2)

  (send g2 play-move 'end)
  (debug-game g2)
  )
