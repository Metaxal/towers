#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require "base.rkt"
         "player.rkt"
         "player-ai-base.rkt"
         bazaar/getter-setter
         bazaar/loop
         bazaar/mutation
         racket/class
         racket/dict
         racket/list
         racket/pretty
         )

(provide player-alpha-beta%
         player-alpha-beta-simu%
         alpha-beta-logger)

(define-logger alpha-beta)

#| Possible optimizations
- find-all-possible-moves does a lot of work. A lot of it is redundant.
- copy-game is intensive too, as it copies not only the matrix but the plies also.
|#

(define move-depth-max 200) ; max number of moves we allow to consider

(define-player-class player-alpha-beta-simu% "Alpha-Beta simu"
  (class player-ai-base%
    (super-new)))

(define-player-class player-alpha-beta% "Alpha-Beta TXT"
  (class player-ai-base%
    (super-new)

    (inherit-field opponent game master-pos move-points)
    (inherit say find-a-move play-move*
             am-i-player1?
             find-all-possible-moves
             update-view
             ;master-attacked?
             )

    (field [ply-depth-max 1] ; ply-depth max
           [game-simu-dict #f] ; a pool of games, to avoid initializing objects all the time
           [nb-move-total 1]
           [nb-move-remaining 1]
           [stop-search? #f]
           [nb-move-searched 0]
           )

    (getter nb-move-total)
    (getter/setter ply-depth-max stop-search? nb-move-searched)

    ;; Initializes the emty dictionary of simulations
    (define (init-simu-dict)
      (set! game-simu-dict (make-vector move-depth-max #f)))
    
    ;; Returns a new copy of super-game
    (define (copy-game game move-depth)
      (define g (dict-ref game-simu-dict move-depth))
      #;(log-debug "Copying game: ~a (~a)" move-depth g)
      (if g
          (send game copy-to! g) ; copy, but no memory allocated (normally)
          (begin (set! g (send game copy 
                               ;; Dummy players for the simulated game
                               (new player-alpha-beta-simu% [name "simu-pl1"])
                               (new player-alpha-beta-simu% [name "simu-pl2"])))
                 (dict-set! game-simu-dict move-depth g)))
      g)

    ;; Forces the search to stop
    (define/public (stop-search)
      (set! stop-search? #t))
   
    ;; Returns a new game as a copy of super-game with the move played
    (define (simu-game-move game mv move-depth)
      (define g (copy-game game move-depth))
      #;(log-debug "Copy-game, plies: ~a" (send g get-plies))
      (++ nb-move-searched)
      (send (send g get-current-player) play-move mv)
      g)

    ;; Copies a game and plays it until ply-depth reaches 0.
    ;; Returns the best ply (reversed) with its value.
    ;; Implements negamax: http://en.wikipedia.org/wiki/Negamax
    ;; Removing all logs can half the computation time.
    ;; end-turn-first? : first end the turn of the previous player before the first simulation?
    (define (simu-game-ply game ply-depth move-depth
                           alpha beta color)
      (define (log-debug-depth fmt #:ply [ply #f] . args )
        (log-alpha-beta-debug 
         (apply format (string-append (make-string (add1 ply-depth) #\o)
                                      (if ply (make-string (add1 (length ply)) #\.) "")
                                      " " fmt)
                    args)))
      #;(log-debug-depth "Remaining move points: ~a" move-points)
      (cond 
        [(or stop-search?
             (send game get-winner))
         (define val (* color (game-value game ply-depth)))
         #;(log-debug-depth "Leaf val: ~a" val)
         (values #f val)]
        
        [else
         (let move-loop ([game game]
                         [move-depth move-depth]
                         [rev-ply '()]
                         [best-ply #f]
                         [alpha alpha])
           #;(log-debug-depth "rev-rev-ply: ~a" (reverse rev-ply) #:ply rev-ply)
           (define must-end-turn? (send game player-must-end-turn?))
           (cond [(or (send game get-winner)
                      (and must-end-turn?
                           (= ply-depth ply-depth-max)))
                  (define ply-value (* color (game-value game ply-depth)))
                  #;(log-debug-depth "end ply: ~a alpha ~a" (reverse rev-ply) ply-value)
                  (values rev-ply ply-value)]
                 
                 [must-end-turn?
                  ; We start another ply
                  #;(log-debug-depth "Ending turn" #:ply rev-ply)
                  ; Actually end the player's turn
                  (send game end-player-turn)
                  (define-values (_ply ply-value) 
                    (simu-game-ply game (add1 ply-depth) (add1 move-depth)
                                   (- beta) (- alpha) color #;(- color)))
                  (set! ply-value (- ply-value)) ; negamax
                  (when (= 1 ply-depth)
                    (log-debug-depth "ply: ~a alpha: ~a" (reverse rev-ply) ply-value))
                  (values rev-ply ply-value)]
                 
                 [else
                  ; We continue the current ply
                  ; and return the best-ply and best-value
                  #;(log-debug-depth "Testing all possible moves" #:ply rev-ply)
                  (define all-moves (send (send game get-current-player)
                                          find-valid-1moves
                                          #;find-all-possible-moves))
                  (let loop ([best-ply best-ply]
                             [alpha alpha]
                             [moves all-moves])
                    (when (= move-depth 0)
                      (-- nb-move-remaining))
                    (cond [(empty? moves)
                           (values best-ply alpha)]
                          [else
                           (define mv (first moves))
                           #;(log-debug-depth "Simu move: ~a" mv #:ply rev-ply)
                           (define-values (ply val)
                             (move-loop (simu-game-move game mv move-depth)
                                        (add1 move-depth)
                                        (cons mv rev-ply)
                                        best-ply
                                        alpha))
                           (cond [(>= val beta)
                                  #;(log-debug-depth "Beta cut: ~a ~a beta=~a" mv val beta)
                                  (values ply val)]
                                 [(> val alpha)
                                  #;(log-debug-depth "Better value: ~a ~a" mv val)
                                  (loop ply val (rest moves))]
                                 [else
                                  (loop best-ply alpha (rest moves))])]))]))]))
    
    (define/public (find-best-ply)
      (log-debug "Starting Alpha-Beta simulation")
      (init-simu-dict)
      (set! stop-search? #f)
      (set! nb-move-total
            (length (send (send game get-current-player) 
                          find-valid-1moves
                          #;find-all-possible-moves)))
      (set! nb-move-remaining (add1 nb-move-total))
      (set! nb-move-searched 0)
      (define-values (best-ply-rev best-value) 
        (simu-game-ply game 1 0
                       -inf.0 +inf.0 1))
      (values (reverse best-ply-rev) best-value))

    (define ply-to-play '())
    
    (define/override (on-play-move)
      (when (empty? ply-to-play)
        (define-values (ply v) (time (find-best-ply)))
        (say "ply: ~a ; value: ~a ; search nodes (with cuts): ~a" ply v nb-move-searched)
        (set! ply-to-play ply))
      (define mv (first ply-to-play))
      (rest! ply-to-play)
      (play-move* mv))

    (define/override (on-end-game winner)
      (cond [(eq? winner this) (say "Woohoo! I win!")]
            [(eq? winner 'draw) (say "Stop playing like me and maybe we'll have a winner...")]
            [else (say "Damned! I lost...")]))
    
    ;; Returns the heuristic value of the given game.
    ;; pl-num : (or/c 0 1) ; 0 for player 1, 1 for player2
    (define (game-value game ply-depth)
      (define winner (send game get-winner))
      (define me     (send game get-current-player))
      (define opp    (send me   get-opponent))
      (define me-master-attacked? (send me master-attacked?))
      (cond [(eq? winner 'draw) 0]
            [(eq? winner me) (- 1000 ply-depth)] ; win as soon as possible
            [winner (- ply-depth 1000)] ; lose as late as possible
            #;[me-master-attacked?
             (say "Danger: master reachable!")
             (- ply-depth 1000 -1)]
            [else
             (+ (send me get-num-pawns-reserve)
                (- (send opp get-num-pawns-reserve))
                (for/fold ([score 0]) ([(y x c) (send game get-mat)])
                  (+ score (send me cell->relative-cell c)))
                #;(if (send opp master-attacked?)
                    5
                    0))]))
    
    (define/public (get-nb-move-remaining)
      nb-move-remaining)

    ))
