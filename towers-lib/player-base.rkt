#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide player-base%
         player?
         find-player-class
         define-player-class
         get-player-classes
         get-player-gui-classes
         player-gui<%> ; Should probably not be in this lib, but in the towers-gui collection instead
         )

(require "base.rkt"
         bazaar/mutation
         bazaar/getter-setter
         racket/class
         racket/dict
         racket/list
         racket/match
         )

;; A dict that contains associations
;; between the players name and the class
;; if (string? name) then human player
;; else (symbol) then get class from symbol
(define player-class-dict '());(make-hash))

;; Takes a name-str unique to a class and returns the corresponding class%
(define (find-player-class pl)
  (dict-ref player-class-dict pl))

(define (register-player-class cl str)
  (cons! (cons str cl) player-class-dict))
  ;(dict-set! player-class-dict str cl))

(define (get-player-classes)
  (dict-keys player-class-dict))

(define (get-player-gui-classes)
  (for/list ([(str cl) (in-dict player-class-dict)]
             #:when (implementation? cl player-gui<%>))
    str))

;; name-str: a string unique to the class. This string appears in the GUI choice of players.
;; class-id: the class to define
;; class-expr: the class-definition
(define-syntax-rule (define-player-class class-id name-str class-expr)
  (begin
    (define class-id
      (class class-expr (super-new)
        (define/override (get-class-name) name-str)))
    (register-player-class class-id name-str)
    ))


(define player-base%
  (class object% (super-new)

    (init-field name
                [verbose? #t])

    (field [opponent #f] [num-pawns-reserve #f] [move-points #f] [master-pos #f]
           [game #f])

    (getter/setter name opponent num-pawns-reserve move-points master-pos game verbose?)
    
    (define/public (->text)
      (format "~a: ~a/~a" name move-points num-pawns-reserve))

    (define/public (say str #:prefix [prefix ""] . args)
      (when verbose?
        (printf "~a~a says: ~a\n" prefix name 
                (if (empty? args)
                    str
                    (apply format str args)))))

    (define/public (get-class-name)
      ;(class->string this%)
      (first (call-with-values (λ()(class-info this%)) list)))

    (define/public (copy-init g pl opp)
      (set! game g)
      (set! num-pawns-reserve (send pl get-num-pawns-reserve))
      (set! move-points       (send pl get-move-points))
      (set! master-pos        (send pl get-master-pos))
      ;(set! verbose?          (send pl get-verbose?))
      (set! opponent opp)
      )


    ; pubment, augment, ... :
    ; http://docs.racket-lang.org/guide/classes.html#%28part._inner%29
    (define/pubment (init-game nb-cells opp)
      (set! num-pawns-reserve (- nb-cells 4))
      (set! move-points 0)
      (set! opponent opp)
      ;(printf "in init-game, class: ~a\n" (get-class-name))
      (inner (void) init-game nb-cells opp)
      )

    (define/public (current-player?)
      (eq? this (send game get-current-player)))

    (define/public (am-i-player1?)
      (eq? this (send game get-player1)))

    (define/public (can-i-move?)
      (and (current-player?)
           (not (send game get-winner))))

    ;; returns the cell number so that it is positive for us,
    ;; and negative for the opponent.
    ;; (instead of positive for player1 and negative for player2)
    (define/public (cell->relative-cell c)
      (if (eq? this (send game cell-owner c))
          (abs c)
          (- (abs c))))

    (define/public (get-cell xc yc)
      (send game get-cell xc yc))

    (define/public (get-relative-cell xc yc)
      (cell->relative-cell (send game get-cell xc yc)))

    (define/public (pos->cell c-pos)
      (send game pos->cell c-pos))

    (define/public (pos-num-pawns c-pos)
      (send game cell-num-pawns (pos->cell c-pos)))

    (define/public (cell-num-pawns xc yc)
      (send game cell-num-pawns (get-cell xc yc)))

    (define/public (pos-has-master? pos)
      (send game cell-has-master? (pos->cell pos)))

    (define/public (pos-owner pos)
      (send game cell-owner (pos->cell pos)))

    (define/public (reduce-move-points n)
      (set! move-points
            (- move-points n)))

    (define/public (add-to-reserve n)
      (set! num-pawns-reserve (+ num-pawns-reserve n)))

    (define/public (must-end-turn?)
      (= 0 move-points))

    (define/public (end-turn)
      (set! move-points 0))

    (define/public (init-turn)
      (set! move-points num-pawns-reserve))

    (define/public (on-end-game winner)
      (void))
    
    (define/public (on-play-ply #:between [between void] #:after [after void])
      (void))

    ;; Must call only ONE of the actions
    (define/public (on-play-move)
      (void))

    (define/public (do-end-turn)
      (if (current-player?)
          (send game end-player-turn)
          (error "Not allowed to end turn")))

    ;(define/public (do-import)
     ; (void))

    (define/public (update-view)
      (void))

    (define/public (play-move mv)
      (cond [(not (current-player?))
             (say (format "WARNING: not my turn to play: ~a" mv))
             #f]
            [(must-end-turn?)
             ;(say "end-turn")
             (do-end-turn)
             #f]
            [(not mv)
             ;(say "No move -> end-turn")
             (do-end-turn)
             #f]
            [else
             ;(say mv)
             (send game play-move mv)])

      (update-view)
      )

    ;; Must be called in tail position!
    ;; Plays one move, then calls on-play-move back
    (define/public (play-move* mv)
      (play-move mv)
      ; tail position:
      (when (can-i-move?)
        (if (must-end-turn?)
            (play-move #f) ; end turn
            ; move again:
            (on-play-move))))

    ;; Moves a pawn/tower along a path
    ;; If the master is moved and attacks a higher tower,
    ;; it attemps to import pawns to have the same height.
    ;; Returns #t if the path could be played entirely, #f otherwise.
    (define/public (play-path path)
      (cond [(or (empty? path) (empty? (rest path)))] ; path ended. -> #t
            [(not (current-player?))
             (say "WARNING: Not my turn to play path")
             #f] ; and stop here
            [(must-end-turn?)
             (say (format "Could not end path: ~a" path))
             (do-end-turn)
             #f]
            [else
             (let ([src (first path)]
                   [dst (second path)])
               (if (and (empty? (rest (rest path))) ; last move
                        (pos-has-master? src)
                        (< (pos-num-pawns src) (pos-num-pawns dst)))
                   (begin (play-move '(import 1))
                          (play-path path))
                   (begin (play-move (cons 'move (append src dst (list #f))))
                          (play-path (rest path)))))]))

    (define/public (master-attacked?)
      (send game find-attacked-path* master-pos #t #:attacker opponent))

))

(define (player? p)
  (is-a? p player-base%))

(define player-gui<%> (interface ()))


