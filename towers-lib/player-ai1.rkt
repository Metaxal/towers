#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide player-ai1%)

(require "base.rkt"
         "player-base.rkt"
         "player.rkt"
         "player-alpha-beta.rkt"
         "game.rkt"
         bazaar/matrix
         bazaar/getter-setter
         bazaar/debug
         racket/class
         racket/match
         racket/list
         racket/pretty
         )

#| Ideas:
~Mirror playing
  - have as many towers as opponent (and same height)
  - export as many pawns as opponent
  - verify after move that that does not expose the master
  - if the master is exposed, hide it.

- To make it more robust, use simulation:
does this move imply bad things?

|#

(define-player-class player-ai1% "AI-1"
  (class* player-alpha-beta% (player-gui<%>)
    (super-new)

    (inherit-field game master-pos num-pawns-reserve opponent move-points)
    (inherit current-player? am-i-player1?
             get-cell
             find-my-cells
             pos-num-pawns
             pos-has-master?
             pos-owner
             cell->relative-cell
             cell-num-pawns
             must-end-turn?
             can-i-move?
             do-end-turn
             play-move
             play-path
             master-attacked?
             say
             )

    ;; takes the first element of l if it exists,
    ;; or returns #f
    (define (first-or-false l)
      (and l (not (empty? l)) (list? l) (first l)))

    ;; Returns the first path that reaches a position by player
    ;(define/public (try-reach-pos pos [player this])
    ;  (send game find-path (first pos) (second pos) player)
    ;  )

    ;; Try to find a path that attacks pos
    (define/public (attacked-path pos)
       (send game find-attacked-path* pos #t))

    (define/public (raise-path pos)
      (send game find-raise-path* pos #t))

    (define/public (nb-attacks pos)
       (length (send game find-attacked-path* pos)))

    (define/public (nb-protections pos [height #f])
      (length
       (send game find-protect-path* pos #:height height)))


    (define game-simu #f)
    (define player1-simu (new player% [name "pl1-simu"]))
    (define player2-simu (new player% [name "pl2-simu"]))

    ;; Applies proc-do to a simulated game (a copy of the original) + players.
    ;; If the return value is not #f, proc-test is applied to simulated game+players.
    ;; If both return not #f, proc-do is applied to the real game+players.
    ;; Returns the return value of proc-test.
    ;; The first parameter of the procs is `this' or it equivalent in the simulation,
    ;; and the second is its opponent.
    (define (try-simu-proc proc-do proc-test)
      (if game-simu
          (send game copy-to! game-simu)
          (set! game-simu (send game copy player1-simu player2-simu)))
      (let* ([me  (if (am-i-player1?) player1-simu player2-simu)]
             [opp (if (am-i-player1?) player2-simu player1-simu)]
             [res-do   (proc-do game-simu me opp)]
             [res-test (and res-do (proc-test game-simu me opp))]
             )
        (when res-test
          (proc-do game this opponent))
        res-test))

    ;; Macro helper for try-simu-proc.
    ;; The game and players arguments to the procs are given in ().
    ;; The last body expression is taken as the proc-test,
    ;; what precedes being the do-proc.
    (define-syntax-rule (try-simu (id me opp) body-do ... test)
      (try-simu-proc (λ(id me opp) body-do ...)
                     (λ(id me opp) test)))

    ;; Plays path in simu.
    ;; If master is not attacked aterwards, play it for real.
    ;; Returns #f if fails, not #f otherwise.
    (define (try-safe-path path)
      (try-simu (game me opponent) ; shadow
                (send me play-path path)
                ; test:
                (not (send me master-attacked?))))


    #|
    (try-for/best (paths)
    ...)

    Each path is tried in simulation, and returns a board value.
    The path that returns the best value is played.
    ~alpha-beta, but simpler.
    If not path leads to improvment or there is no path, return #f.
    |#

    (define/override (on-play-move)
      (let-values ([(my-cells opp-cells free-cells) (find-my-cells)])

        ;; Try to place the master on a cell that cannot be reached by the opponent.
        ;; Returns #f if cannot.
        (define (master-run-away)
          (or
           (for/or ([pos (append free-cells my-cells)])
             (let ([path
                    (and (<= (send this pos-num-pawns pos) 1) ; cannot put master on a tower
                         (send game find-from-to-path this master-pos pos))])
               (and path (try-safe-path path))))
           (begin (say "WTF?!! Let me outa here!!") #f)))

        ; If the opponent master can be reached, go for it:
        (let ([path-to-opp-master (attacked-path (send opponent get-master-pos))])
          (when path-to-opp-master
            (displayln path-to-opp-master)
            (play-path path-to-opp-master)))

        ; is our own master reachable by opponent?
        ; should check all paths, not just the first one!
        (let ([all-paths-to-master (send game find-attacked-path* master-pos)])
          (cond [(empty? all-paths-to-master)
                 (void)] ; safe
                [(> (length all-paths-to-master) 1)
                 (say "Too many attacks! Run away!")
                 (master-run-away)]
                [else
                 (let* ([path-to-master (first all-paths-to-master)]
                        [offender-pos   (first path-to-master)]
                        [offender-protected?  (> (nb-protections offender-pos) 0)]
                        [offender-protected1? (> (nb-protections offender-pos 1) 0)]
                        [paths-to-offender
                         (send game find-attacked-path* offender-pos)]
                        [master-path-to-offender
                         (findf (λ(p)(equal? (first p) master-pos))
                                paths-to-offender)]
                        [path-to-offender
                         (first-or-false
                          (remove master-path-to-offender paths-to-offender))])
                   (say "Are you trying to capture my master?!")
                   (cond [(and offender-protected? path-to-offender
                               (try-safe-path path-to-offender)
                               (say "I can capture your offender! :p")
                               )]
                         [offender-protected1?
                          (say "Run away!! that's too protected for me!")
                          (master-run-away)]
                         [(and master-path-to-offender
                               (try-safe-path master-path-to-offender)
                               (say "I can capture your offender with my master \\o/")
                               )]
                         [(and path-to-offender
                               (try-safe-path path-to-offender)
                               (say "Let's remove that thorn")
                               )]
                         [else
                          (say "Run away!!")
                          (master-run-away)]))]))



        ;; If there is a reachable opponent pawn that is not sufficiently covered,
        ;; capture it
        (for ([pos opp-cells])
          (let ([path (attacked-path pos)])
            (and path ; be sure it's a list
                 (<= (nb-protections
                      pos (if (equal? (first path) master-pos)
                              1
                              (pos-num-pawns (first path))))
                     (nb-attacks pos))
                 (say "One of your cells is not covered! :p")
                 (try-safe-path path))))

        ;; TODO: get closer to opponent master
        ;; TODO: attack a pawn/tower that blocks access to the master

        ;; TODO: handle towers...

        ;; do I have a pawn/tower threatened by an opponent tower
        ;; that is not covered by a tower of same height?
        ;; if so, raise a covering tower

        ;; Mirror the number of reserve pawns of the opponent
        (when (< num-pawns-reserve (send opponent get-num-pawns-reserve))
          (unless (for/or ([path-to-master (send game find-raise-path* master-pos)])
                    (say "try path ~a" path-to-master)
                    (try-safe-path path-to-master))
            (say "Cannot export pawn :(")))

        ;; Raise pawns to towers when attacked by a tower
        (for ([pos my-cells])
          (and
           ; verify that this cell still is ours (this can have changed if the cell raised another one)
           (pos-owner pos)
           ; we are a pawn:
           ;(= 1 (pos-num-pawns pos))
           ; attacked by tower:
           (send game find-attacked-path* pos #t
                 #:test (λ(path cell)
                          (> (send game cell-num-pawns cell)
                             (pos-num-pawns pos))))
           ; not protected by a tower:
           (= 0 (nb-protections pos (add1 (pos-num-pawns pos))));2))
           ; move onto another pawn:
           (say "Let's raise that!")
           (or (for/or ([rev-raise-path
                         (send game find-raise-path* pos)])
                 (debug-var rev-raise-path)
                 (try-safe-path rev-raise-path));(reverse rev-raise-path)))
               (say "nope... cannot raise that one."))))


        ; move a pawn toward the opponent master, but be sure to remain protected!

        (when (current-player?)
          (play-move '(import 1)) ; to avoid draw games
          (when (current-player?)
            (do-end-turn)))
        ))

    ))




