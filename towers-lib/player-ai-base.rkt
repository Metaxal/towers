#lang racket/base

(require "player.rkt"
         bazaar/matrix
         bazaar/mutation
         bazaar/list
         racket/class
         racket/match
         racket/list
         )

(provide player-ai-base%)

(define player-ai-base%
  (class player% (super-new)

    (inherit-field game master-pos num-pawns-reserve opponent move-points)
    (inherit current-player?
             get-cell
             pos-num-pawns
             cell->relative-cell
             cell-num-pawns
             must-end-turn?
             can-i-move?
             do-end-turn
             on-play-move
             play-move
             play-move*
             say
             )
    
    ;; Makes the player play a whole turn.
    ;; Calls `between' between each move, and `after' after the ply.
    ;; Does not actually and the ply?
    (define/override (on-play-ply #:between [between void] #:after [after void])
      (let loop ()
        (unless (must-end-turn?)
          (on-play-move)
          (between)
          (loop)))
      (do-end-turn)
      (after))


    (define/public (move-cost move)
      (match move
        [(list 'import n)
         n]
        [(or 'end #f 'resign)
         move-points]
        [(list 'move xi yi xf yf n)
         (* (or n (cell-num-pawns xi yi))
            (+ (abs (- xf xi)) (abs (- yf yi))))]
        ))
    
    ;; Returns the list of valid moves in a range of 1 cell around each
    ;; owner cell, including (when possible) 'end, '(import 1), and
    ;; master tower out.
    (define/public (find-valid-1moves)
      (define nb-cells (send game get-nb-cells))
      (define moves '(end))
      (when (can-import?)
        (cons! '(import 1) moves))
      (when (> move-points 0)
        (matrix-for-each
         (send game get-mat)
         (λ(y x c)
           (let ([c (cell->relative-cell c)])
             (when (> c 0) ; owner cell
               (define height (send game cell-num-pawns c))
               (when (<= height move-points)
                 (for ([dx '(-1 0 1 0)]
                       [dy '(0 -1 0 1)])
                   (define x2 (+ x dx))
                   (define y2 (+ y dy))
                   (when (and (< -1 x2 nb-cells) (< -1 y2 nb-cells))
                     (when (send game move x y x2 y2 height #:test? #t)
                       (cons! (list 'move x y x2 y2 height) moves))
                     ; Master tower-out
                     (when (and (send game cell-has-master? c)
                                (> height 1)
                                (send game move x y x2 y2 1 #:test? #t))
                       (cons! (list 'move x y x2 y2 1) moves))))))))))
      moves)

    (define/public (find-my-cells)
      (let ([my-cells '()]
            [opp-cells '()]
            [free-cells '()]
            )
        (matrix-for-each
         (send game get-mat)
         (λ(i j c)
           (let ([c (cell->relative-cell c)])
             (cond [(> c 0)
                    (cons! (list j i) my-cells)]
                   [(< c 0)
                    (cons! (list j i) opp-cells)]
                   [else (cons! (list j i) free-cells)]))))
        ;(printf "cells: ~a\n~a\n~a\n" my-cells opp-cells free-cells)
        (values my-cells opp-cells free-cells)))

    ;; Returns #f if the move is not possible,
    ;; otherwise returns the move
    (define/public (can-move? ci-pos cf-pos [n #f])
      ;(printf "can-move: ~a ~a ~a\n" ci-pos cf-pos n)
      (and ci-pos cf-pos
           (let-values ([(cxi cyi) (apply values ci-pos)]
                        [(cxf cyf) (apply values cf-pos)])
             (and (send game move cxi cyi cxf cyf n #:test? #t)
                  (list 'move cxi cyi cxf cyf n)))))

    (define/public (master-height)
      (send game cell-num-pawns (get-cell (first master-pos) (second master-pos))))

    (define/public (can-move-out-of-master? cf-pos)
      (and (> (master-height) 1) ; Master is a Tower
           (can-move? master-pos cf-pos 1)))

    (define/public (can-raise-master? ci-pos)
      (and (can-move? ci-pos master-pos)))

    (define/public (can-import?)
      (and (send game can-import?)
           (list 'import 1)))


    ;; Obsolete with find-valid-1moves
    (define/public (find-pos-possible-moves pos [tower-out #f])
      (let-values ([(cx cy) (apply values pos)])
        (let* ([height (pos-num-pawns pos)]
               [height (min (or tower-out height height))]
               [dist-max (quotient move-points height)]
               [last-cell (- (send game get-nb-cells) 1)]
               )
        (filter
         (λ(x)x)
         (append
          (for/list ([i (in-range cx last-cell)]
                     [n (in-range dist-max)]
                     )
            (can-move? pos (list (+ i 1) cy) height))
          (for/list ([i (in-range cx 0 -1)]
                     [n (in-range dist-max)])
            (can-move? pos (list (- i 1) cy) height))
          (for/list ([j (in-range cy last-cell)]
                     [n (in-range dist-max)])
            (can-move? pos (list cx (+ j 1)) height))
          (for/list ([j (in-range cy 0 -1)]
                     [n (in-range dist-max)])
            (can-move? pos (list cx (- j 1)) height))
          )))))

    (define/public (find-all-possible-moves)
      (let*-values ([(my-cells opp-cells free-cells) (find-my-cells)])
        (append
         (if (and (> (master-height) 1) (not (send game locked-cell? master-pos)))
             (find-pos-possible-moves master-pos 1)
             '())
         (append-map (λ(c)(find-pos-possible-moves c)) my-cells)
         (if (can-import?) (list '(import 1)) '())
         (list 'end)
         )))

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;; Random move selection ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (define (choose-cell cell-list)
      (and (not (empty? cell-list))
           (choose cell-list)))

    ;; Returns one possible move
    ;; Tries to keep correct proportions between the different strategies
    ;; (attack, defense, import, etc.)
    ;; Probably too simple.
    (define/public (find-a-move)
      (let ([moves (find-all-possible-moves)])
        (and (not (empty? moves))
             (choose moves))))

    ;; Does NOT consider draw games.
    (define/public (board-value)
      (+ num-pawns-reserve
         (- (send opponent get-num-pawns-reserve))
         (for/fold ([score 0])
                   ([(y x c) (send game get-mat)])
           (+ score (cell->relative-cell c)))))

    ))
