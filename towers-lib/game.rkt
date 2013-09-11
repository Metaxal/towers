#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require "base.rkt"
         "player-base.rkt"
         (prefix-in rules: "rules.rkt")
         (prefix-in network: "connection.rkt")
         bazaar/mutation
         bazaar/matrix
         bazaar/getter-setter
         bazaar/version
         bazaar/list
         bazaar/text-table ; to display the text game
         racket/bool
         racket/list
         racket/class
         racket/match
         racket/math
         racket/format
         racket/string
         )

;;; This is the core of the game,
;;; it implements the game rules and dynamics.

(module+ test 
  (require bazaar/rackunit))

(define (straight-line? xi yi xf yf)
  (xor (= 0 (- xi xf)) (= 0 (- yi yf))))  ; we don't want both as this would mean "no move". 

; Definition of a game:
;(define-struct game 
(define game%
  (class* object% (game<%>)
    (super-new)
    
    (init-field nb-cells ; [5 - 10]
                [version current-version] ; string
                [rules '()]
                [player1 #f] ; player%
                [player2 #f]
                [plies '(())] ; plies initialized with an empty first ply
                )
    ; if player1 or player2 is not provided:
    (init [player1-name #f] ; string
          [player1-class #f] ; symbol, not a real class
          [player2-name #f] [player2-class #f]
          [no-init? #f]
          )
    
    (field [mat #f]  ; the matrix, should normally not be given
           [current-player #f]
           [winner #f]
           [locked-cells '()]
           [replaying? (make-parameter #f)]

           ;; Number of imported pawns during the current ply
           [nb-imported 0]
           [nb-exported 0]
           )
    
    (define/public (get-replaying?) (replaying?))
    (define/public (set-replaying? b) (replaying? b))
    
    (getter/setter mat version rules nb-cells plies
                   player1 player2 current-player winner
                   )
    
    (unless (and (or player1 (and player1-name player1-class))
                 (or player2 (and player2-name player2-class)))
      (error "Either player or name and player-class must have a value"))
    
    (unless player1
      (set! player1 (new (find-player-class player1-class) [name player1-name])))
    
    (unless player2
      (set! player2 (new (find-player-class player2-class) [name player2-name])))
    
    (send player1 set-game this)
    (send player2 set-game this)
    
    (define/public (get-name1)
      (send player1 get-name))
    (define/public (get-name2)
      (send player2 get-name))
    (define/public (get-current-name)
      (and current-player (send current-player get-name)))
    
    (define/public (game->list)
      (list version rules nb-cells 
            (get-name1) (get-name2)
            (send player1 get-class-name) (send player2 get-class-name)
            plies)) ; plies MUST be last (because of server parsing)
    
    (define/public (obsolete-client-for-game)
      (version<? current-version version))

    (define/public (obsolete-game-for-client)
      (version<? version game-min-version))
    
    ;; Rules
    
    (define/public (specific-rule? rule)
      (rules:specific-rule? rules rule))
    
    (define (check-rule? rule val)
      (rules:check-rule? rules rule val))
    
    (define (cell->string row col c)
      (define n (cell-num-pawns c))
      (define-values (l r) (if (< c 0) (values "(" ")") (values "{" "}")))
      (define s (if (> n 1) (number->string n) " "))
      (when (> n 0)
        (surround! l s r))
      (when (cell-has-master? c)
        (surround! "[" s "]"))
      (when (locked-cell? (list col row))
        (surround! "<" s ">"))
      (~a s #:align 'center #:min-width 7))
    
    ; This should be in a towers-txt collection? (not sure, could still be useful for the server)
    (define/public (->string)
      (define tb 
        (table-framed 
         (cons '< (append
                   (add-between (build-list nb-cells (λ(n)(list "" 7))) '+)
                   '(>)))
         #;'rounded 'double))

      (define ll
        (append
         (list (table-first-line tb))
         (add-between
          (for/list ([row nb-cells])
            (table-row tb (for/list ([col nb-cells])
                            (define c (matrix-ref mat row col))
                            (cell->string row col c))))
          (table-mid-line tb))
         (list (table-last-line tb))))
      (string-join ll "\n" #:after-last "\n"))
      
    (define/public (display-text)
      (display (->string)))
    
    ;;;;;;;;;;;;;
    ;;; Cells ;;;
    ;;;;;;;;;;;;;

    ;; A cell:
    ;; +- (nb-pawns + 1000-if-master)
    ;; + : player-one ; - : player-two
    
    (define/public (cell-owner c)
      (cond [(> c 0) player1]
            [(< c 0) player2]
            [else #f]))
    
    (define/public (cell-owner? c [player current-player])
      (eq? (cell-owner c)
           player))
    
    (define/public (cell-num-pawns c)
      (let ([a (abs c)])
        (if (> a 1000)
            (- a 1000)
            a)))
    
    (define/public (cell-has-master? c)
      (> (abs c) 1000))
    
    (define (make-cell owner num-pawns has-master?)
      ((if (eq? owner player1) + -)
       0
       num-pawns
       (if has-master? 1000 0)))
    
    (define/public (get-cell xc yc)
      (matrix-ref mat yc xc))
    
    (define/public (pos->cell pos)
      (get-cell (first pos) (second pos)))
    
    ;; Cell setters
    
    (define (set-cell-num-pawns! mat y x np)
      (let ([c (matrix-ref mat y x)])
        (matrix-set! mat y x (make-cell (cell-owner c) np (cell-has-master? c)))))
    
    (define (set-cell-owner! mat y x owner)
      (let ([c (matrix-ref mat y x)])
        (matrix-set! mat y x (make-cell owner (cell-num-pawns c) (cell-has-master? c)))))
    
    (define (set-cell-has-master?! mat y x master?)
      (let ([c (matrix-ref mat y x)])
        (matrix-set! mat y x (make-cell (cell-owner c) (cell-num-pawns c) master?))))
    
    
    ;; Free cells + free-path
    
    (define/public (free-cell? pos)
      (let ([c (matrix-ref mat (second pos) (first pos))])
        (not (cell-owner c))))
    
    (define/public (free-cell-path-list xi yi xf yf)
      (let* ([xl (- xf xi)]
             [yl (- yf yi)]
             [dx (sgn xl)]
             [dy (sgn yl)]
             )
        (for/list ([i (in-range 1 (max (abs xl) (abs yl)))])
          (list (+ xi (* dx i)) (+ yi (* dy i))))))
    
    ;; Checks if it is possible to move from (xi yi) to (xf yf) in STRAIGHT LINE
    ;; All cells in-between must be free (but the first and last may not be).
    ;; Checks about the last cell (is it possible to capture that tower?)are NOT done here.
    (define (free-cell-path? xi yi xf yf)
      (for/and ([pos (free-cell-path-list xi yi xf yf)])
        (free-cell? pos)))

    ;; Locked cells 
    
    (define (reset-locked-cells)
      (set! locked-cells '()))
    
    (define (add-locked-cell c) 
      (set! locked-cells (cons c locked-cells)))
    
    ;; Tells if a position c = (xc yc) is locked for the current turn
    (define/public (locked-cell? c)
      (member c locked-cells))
    
    ;;;;;;;;;;;;;;;;;;;;;;
    ;;; Current player ;;;
    ;;;;;;;;;;;;;;;;;;;;;;
    
    ;; Tells if a position lc = (xc yc) is the cell of the current player's master position
    (define (master-cell-current-player? lc)
      (equal? lc (send current-player get-master-pos)))          
    
    (define (add-to-current-reserve n)
      (send current-player add-to-reserve n))
    
    (define (reduce-move-points n)
      (send current-player reduce-move-points n))
    
    (define/public (player-must-end-turn?)
      (= 0 (send current-player get-move-points)))
    
    ;; WARNING: also used for replaying!
    ;; so this name is not really accurate.
    ;; May be overriden in network-game%.
    (define/public (can-current-player-play?)
      (not winner)) ; Is it really all?
    
    ;; Is player1 the current player?
    (define/public (current-player1?)
      (eq? current-player player1))

    ;;;;;;;;;;;;;
    ;;; Plies ;;;
    ;;;;;;;;;;;;;
    
    (define/public (last-ply)
      (last plies) ; Should not fail! (i.e., there should always be one)
      #;(if (empty? plies)
          '()
          (last plies)))
    
    (define/public (get-current-ply)
      (last-ply))
    
    ;; Returns whether we have just started a new ply
    (define/public (new-ply?)
      (empty? (last-ply)))
    
    ;; May be overriden in network-game%
    (define/public (new-ply)
      (when (and (not (replaying?))
                 (or (empty? plies)
                     (not (empty? (get-current-ply)))))
        (set! plies (consr '() plies))))

    (define/public (replace-current-ply ply)
      #;(log-debug (list 'replace-current-ply 'plies plies 'last-ply (last-ply) 'new-ply ply))
      (unless (replaying?)
        (set! plies (replace-last plies ply))
        #;(log-debug (list 'new-plies plies))))
    
    (define (add-move-to-current-ply move)
      (log-debug "add-move ~a last-ply: ~a plies: ~a replaying? ~a"
                 move
                 (last-ply)
                 "[skip]"#;plies
                 (replaying?))
      (unless (replaying?)
        (replace-current-ply (consr move (last-ply))))
      (log-debug "New plies: ~a" plies))
    
    ;;;;;;;;;;;;;;;
    ;;; Actions ;;;
    ;;;;;;;;;;;;;;;
              
    (define/public (try-switch-player [force #f] [locked '()])
      (let ([switch? (or force winner 
                         (and (replaying?)
                              (player-must-end-turn?)))])
        (when switch?
          (export-pawns)

          (send current-player end-turn)

          (new-ply)

          (set! locked-cells locked)
          (set! nb-imported 0)
          (set! nb-exported 0)
          
          (set! current-player (send current-player get-opponent))
          (send current-player init-turn)
          
          (unless (replaying?)
            (if winner
                (begin (send player1 on-end-game winner)
                       (send player2 on-end-game winner))
                (send current-player on-play-move)))))) ; tail position
    
    (define/public (current-ply-only-imports?)
      (andmap (match-lambda [(list 'import n) #t]
                            ['import #t]
                            [else #f])
              (get-current-ply)))
    
    (define/public (can-import? [n-import 1])
      (import-pawn n-import #:test? #t))

    (define/public (import-pawn [n-import 1] #:test? [test? #f])
      (let* ([nb-move-points (send current-player get-move-points)]
             [n-import (min nb-move-points n-import)]
             [xym (send current-player get-master-pos)]
             [xm (first  xym)]
             [ym (second xym)]
             [mc (matrix-ref mat ym xm)]
             [can-import? (and ; cannot import if master is locked:
                            (not (locked-cell? xym))
                            (> n-import 0)
                            (check-rule? 'import-first (current-ply-only-imports?))
                            )]
             )
        (if test?
            ; return value:
            can-import?
            (when can-import?
              (set-cell-num-pawns! mat ym xm (+ (cell-num-pawns mc) n-import))
              (add-to-current-reserve (- n-import))
              
              (+= nb-imported n-import)
              
              ; ending move:
              (add-move-to-current-ply (list 'import n-import))
              
              (reduce-move-points n-import)
              ; check if this is the end of the player's turn:
              (try-switch-player))))) ; tail position
    


    ;; Export pawns to the reserve:
    (define/public (export-pawns)
      (let* ([xym (send current-player get-master-pos)]
             [xm (first  xym)]
             [ym (second xym)]
             [mc (matrix-ref mat ym xm)]
             [n-pawn-mc (cell-num-pawns mc)]
             [first-ply? (= (length plies) 1)]
             [n-export (- n-pawn-mc 1)]
             )
        (when (> n-export 0)
          (set-cell-num-pawns! mat ym xm (- n-pawn-mc n-export))
          
          (add-to-current-reserve n-export)
          (+= nb-exported n-export)
          )))
    
    ;; Try to move a tower from source cell (xi yi) to target cell (xf yf)
    ;; SHOULD raise exceptions when a move is illegal?
    ;; test? : if #t, does not modify the game, just tries to make the move,
    ;; returns #f if the move is invalid, or the number of required 
    ;;   move points if valid.
    (define/public (move xi yi xf yf [move-nb-pawns #f]
                              #:test? [test? #f])
      (let* ([ci                    (matrix-ref mat yi xi)]
             [ci-pawns              (cell-num-pawns ci)]
             [move-nb-pawns         (or move-nb-pawns ci-pawns)]
             [ci-remaining-pawns    (- ci-pawns move-nb-pawns)]
             [splitting?            (> ci-remaining-pawns 0)]
             [move-master?          (and (cell-has-master? ci) (not splitting?))]
             [cf                    (matrix-ref mat yf xf)]
             [cf-pawns              (cell-num-pawns cf)]
             [cf-owner              (cell-owner cf)]
             [raising?              (cell-owner? cf)]
             [move-normal?          (or raising? (not cf-owner))]
             [move-attack?          (and (not move-normal?) (>= move-nb-pawns cf-pawns))]
             [move?                 (or move-normal? move-attack?)]
             [num-cell-move         (+ (abs (- xi xf)) (abs (- yi yf)))]
             [required-move-points  (* num-cell-move move-nb-pawns)]
             [can-move? (and (or-log (cell-owner? ci)
                                     "Not owner of source cell") ; we must own this cell
                             (or-log (straight-line? xi yi xf yf)
                                     "Not moving in straight line")
                             (or-log (<= 1 
                                         required-move-points 
                                         (send current-player get-move-points))
                                     "Wrong number of move points")
                             (or-log (free-cell-path? xi yi xf yf)
                                     "The path to the target is not free")
                             (or-log (not (locked-cell? (list xi yi)))
                                     "Source cell is locked")
                             (or-log (not (locked-cell? (list xf yf)))
                                     "Target cell is locked")
                             (or-log (or (cell-has-master? ci) (not splitting?) ; no-tower-out
                                         (specific-rule? 'tower-out)) ; allowed if specific rule
                                     "Cannot split a tower")
                             (or-log (not (and raising? (> move-nb-pawns 1)))
                                     "Cannot raise tower by more than 1")
                                      ; cannot put the master on a tower.
                             (or-log (not (and move-master? raising? (> cf-pawns 1)))
                                     "Cannot put the master on a 2+ tower")
                             (or-log move?
                                     "Cannot move"))]
             )
        (if test? 
            ; if we just want to test if moving is possible, and not do the actual move,
            ; return the number of required move points if we can move, or #f otherwise:
            (and can-move? required-move-points)
            ; else, do move.
            ; Below there should be no test for legal moves, only effects.
            (when (and (can-current-player-play?)
                       can-move?
                       ; /!\ These check-rule?s should be in the test above, not here!
                       ;(check-rule? 'no-tower-out (or (cell-has-master? ci) (not splitting?)))
                       ;(check-rule? 'raise-one (not (or (and raising? (> move-nb-pawns 1))
                       ;                                 ; cannot put the master on a tower.
                       ;                                 (and move-master? raising? (> cf-pawns 1)))
                       ;                             ))
                       ;(check-rule? 'no-master-win (not (and move-master? (cell-has-master? cf))))
                       ;(check-rule? 'still-tower-out 
                       ;             (not (and splitting? (moved-cell? (list xi yi)))))
                       )
              (set-cell-num-pawns! mat yi xi ci-remaining-pawns)
              (when (= ci-remaining-pawns 0)
                (matrix-set! mat yi xi 0)) ; empty cell
              
              ; modify the number of pawns on the target cell
              (if move-normal?
                  (set-cell-num-pawns! mat yf xf (+ cf-pawns move-nb-pawns))
                  ; move-attack:
                  (if move-master?
                      (set-cell-num-pawns! mat yf xf (+ cf-pawns move-nb-pawns))
                      (set-cell-num-pawns! mat yf xf move-nb-pawns)
                      ))
              
              (set-cell-owner! mat yf xf current-player)
              
              (if move-normal?
                  (set-cell-has-master?! mat yf xf (or move-master?
                                                       (and cf-owner (cell-has-master? cf))))
                  ; else move-attack:
                  (begin
                    (when (cell-has-master? cf)
                      (set! winner current-player))
                    (set-cell-has-master?! mat yf xf move-master?)))
              
              (when move-master?
                (set-cell-has-master?! mat yi xi #f))
              
              ; modify the recorded position of the master if necessary.
              ; we don't move it if we take only one pawn.
              (when move-master?
                (send current-player set-master-pos (list xf yf)))
              
              ; do we need to lock the destination cell?
              (when (or (specific-rule? 'lock-after-move)
                        (> cf-pawns 0))
                (add-locked-cell (list xf yf))) ; the tower will not be able to move again this turn
                
             
              (when (and (specific-rule? 'lock-split-tower)
                         splitting?)
                (add-locked-cell (list xi yi)))
              
              (add-move-to-current-ply (list 'move xi yi xf yf move-nb-pawns))
              
              ; reduce the current number of move-points of the player:
              (reduce-move-points required-move-points)
              
              ; check if this is the end of the player's turn:
              (try-switch-player)))))  ; tail position

    ;; Does ending the game right now draws the game?
    (define/public (end-turn-draws?)
      (let ([rev-plies (reverse plies)])
        (and (empty? (first rev-plies))
             (> (length rev-plies) 1)
             (equal? (second rev-plies) '(end)))))
    
    (define (try-draw-game)
      (let* ([rev-plies (reverse plies)]
             [rev-plies (if (empty? rev-plies) 
                            '()
                            (if (empty? (first rev-plies))
                                (rest rev-plies)
                                rev-plies))])
        (when (and (>= (length rev-plies) 2)
                   (equal? '(end) (first rev-plies))
                   (equal? '(end) (second rev-plies)))
          (set! winner 'draw))))
      
    
    (define/public (player-end-turn #:test? [test? #f])
      (cond [test?]
            [else
             ; first, try to end the current turn normally
             (unless (player-must-end-turn?)
               (add-move-to-current-ply 'end)
               (unless (replaying?)
                 (try-draw-game)))])

      (try-switch-player #t)) ; force end turn ; tail position

    (define/public (resign #:test? [test? #f])
      (cond [test?]
            [else
             (set! winner (send current-player get-opponent))
             (replace-current-ply '(resign))
             (try-switch-player #t)])) ; force end turn ; tail position
      

    ; Can only undo the moves of the last ply
    (define/public (undo)
      (let ([current-ply (get-current-ply)])
        (unless (empty? current-ply)
          (replace-current-ply (reverse (rest (reverse current-ply)))))))
    
    ;;;;;;;;;;;;;;;;;
    ;;; Replaying ;;;
    ;;;;;;;;;;;;;;;;;
    
    (define/public (play-move mv #:test? [test? #f])
      (log-debug "play-move~a: ~a" (if test? " (test)" "") mv)
      (match mv
        [(list 'move xi yi xf yf n)
         (move xi yi xf yf n #:test? test?)]
        ['end 
         (player-end-turn)]
        [(list 'import n)
         (import-pawn n #:test? test?)]
        ['import
         (import-pawn #:test? test?)]
        ['resign
         (resign)]
        [else (error "Unknown move" mv)]
        ))
    
    ;; ply: list of moves
    ;; We consider that the ply contains only legal moves!
    ;; n is the number of moves to play in the ply (#f for all)
    (define/public (play-ply ply [nb-moves #f])
      (for/last ([move ply]
                 [i (in-naturals)]
                 #:when (or (not nb-moves) (< i nb-moves))
                 )
        (play-move move)
        ; return value:
        ; have we finished the ply?
        (equal? (add1 i) (length ply))))
    
    (define/public (replay-game [nb-plies #f] [nb-moves-last #f])
      
      (parameterize ([replaying? #t])
        (init-game plies)
        
        (for/last ([ply plies]
                   [i (in-naturals)]
                   #:when (or (not nb-plies) (< i nb-plies)))
          (play-ply ply (and (equal? (add1 i) nb-plies) nb-moves-last))))
        
      (if (and 
           ; we go to the last ply:
           (or (not nb-plies) 
               (>= nb-plies (length plies)))
           ; we go to the last move (of the last ply):
           (or (not nb-moves-last)
               (>= nb-moves-last
                   (length (list-ref plies
                                     (sub1 (length plies)))))))
          ; we are at the end of the game
          (try-draw-game)
          ; else, not at the end, we are hence replaying
          (replaying? #t)
          ))
    
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;;; Reachable cell? ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;
    
    (define smat (make-matrix nb-cells nb-cells))
    (getter smat)
    
    ;; (xc yc) is the sarting position to reach the destination cell
    (define (forward-path xc yc)
      (let loop ([xc xc] [yc yc] [path (list (list xc yc))])
        (let ([v (matrix-ref smat yc xc)])
          (if (eq? 'dest v)
              (reverse path)
              (loop (first v) (second v) (cons v path))))))
    
    ;; public for testing, but should not be.
    (define/public (find-next-reachable-cells xc yc)
      (for/list ([dx '(-1 1 0 0)]
                 [dy '(0 0 -1 1)]
                 #:when (let ([x (+ xc dx)] [y (+ yc dy)])
                          (and (>= x 0) (< x nb-cells)
                               (>= y 0) (< y nb-cells)
                               ; we must not have already visisted this cell
                               (not (matrix-ref smat y x)))))
        (let ([x (+ xc dx)] [y (+ yc dy)])
          (matrix-set! smat y x (list xc yc)) ; for backward-path
          (list x y))))

      
    
    (define/public (src-move-points player [move-points #f])
      (cond [(eq? move-points 'all) (send player get-num-pawns-reserve)]
            [move-points]
            [else (if (eq? player current-player)
                      (send player get-move-points)
                      (send player get-num-pawns-reserve))]))
      
    ;; Returns the list of possible paths that can reach position pos-dest=(xc yc)
    ;; under conditions of test.
    ;; Makes no check on dest-cell ! (e.g. locked-cell?)
    ;; player : the player that should own the source cell (of the path to the dest cell)
    ;;   if current-player, then finds a path for the current board
    ;;   otherwise, consider the beginning of the player's turn
    ;;   (for loacked cells and move points)
    ;; test: takes a found path and the initial cell,
    ;;   returns: the value to add to the current return values of find-all-paths
    ;;   If the returned value is #f then it is not added to the path list (for convenience)
    ;; move-points: number of usable move points.
    ;;   If 'all, takes all points in the reserve.
    ;;   If #f, takes the current move-point for the current-player, 
    ;;   or the full reserve points for its opponent.
    ;; stop-at-first?: if #t find-path* returns only the first found path, otherwise #f
    ;;   instead of a list of paths.
    ;; Algorithm: explore the matrix from neighbour to neighbour, starting with (xc yc).
    ;;   fills a helper matrix smat with the origin cell (to remember the path).
    ;;   when the value in smat is #f, this cell has not been visited yet.
    ;;   A queue of the cells to explore is maintained.
    (define/public (find-path* pos-dest [player current-player] 
                               [test (λ(path c) path)]
                               #:move-points [move-points #f]
                               #:stop-at-first? [stop-at-first? #f])
      (let* ([xc-dest        (first pos-dest)]
             [yc-dest        (second pos-dest)]
             [c-dest         (pos->cell pos-dest)]
             [dest-master?   (cell-has-master? c-dest)]
             [dest-owner     (cell-owner c-dest)]
             [attack?        (and dest-owner (not (eq? dest-owner player)))]
             [dest-num-pawns (if (and dest-master? attack?)
                                 1 ; when attacked, consider the master as a simple pawn
                                 (cell-num-pawns c-dest))]
             [dest-locked?   (locked-cell? (list xc-dest yc-dest))]
             [src-current-player? (eq? player current-player)]
             [move-points    (src-move-points player move-points)]
             )
        (matrix-fill! smat #f)
        (matrix-set! smat yc-dest xc-dest 'dest)
        ; recurrence begin here:
        (let loop ([queue (find-next-reachable-cells xc-dest yc-dest)]
                   [return-val (if stop-at-first? #f '())])
          (if (empty? queue) 
              return-val
              (let* ([pos (first queue)]
                     [xc  (first  pos)]
                     [yc  (second pos)]
                     [c   (get-cell xc yc)]
                     [owner       (cell-owner c)]
                     [c-num-pawns (cell-num-pawns c)]
                     )
                (cond [(> (+ (abs (- xc xc-dest)) (abs (- yc yc-dest))) 
                          move-points)
                       ; if we don't have enough move points for a single pawn to reach 
                       ; the destination, stop early
                       return-val]
                      [(and (eq? owner player) 
                            ; the current player cannot play a locked cell:
                            (not (and src-current-player?
                                      (locked-cell? pos)))
                            (let ([path (forward-path xc yc)])
                              (and 
                               ; verify that we have enough move points:
                               (<= (* c-num-pawns (sub1 (length path))) move-points)
                               (let ([val (test path c)])
                                 (if stop-at-first?
                                     val
                                     (loop (rest queue) 
                                           (if val (consr val return-val) return-val))
                                     )))))]
                      [(not owner)
                       (loop (append (rest queue)
                                     (find-next-reachable-cells xc yc))
                             return-val)]
                      [else (loop (rest queue) return-val)] ; do not add cells to the queue
                      ))))))
    

    ;; Returns a path from src to dest.
    ;; Makes no check on destination cell!
    (define/public (find-from-to-path player pos-src pos-dest)
      (find-path*
       pos-dest
       player
       #:stop-at-first? #t
       (λ(path cell)
         (and (equal? pos-src (first path))
              path))))
    
    ;; Finds all paths that can raise the destination pawn/tower
    (define/public (find-raise-path* pos-dest [stop-at-first? #f])
      (find-path*
       pos-dest
       (cell-owner (pos->cell pos-dest))
       #:stop-at-first? stop-at-first?
       (λ(path cell)
         (and (not (cell-has-master? cell)) ; don't want to raise the cell with the master
              (= 1 (cell-num-pawns cell)) ; can only raise by one
              path))))
    
    ;; Finds all paths that can protect the destination cell.
    ;; Note: The number of paths gives the number of protection.
    ;; height: height of the cells that can protect the dest cell.
    ;;   default: height of the dest cell.
    ;;   Can be overriden if cell attacked by master (height=1).
    (define/public (find-protect-path* pos-dest [stop-at-first? #f]
                                       #:height [height #f])
      (let* ([c-dest (pos->cell pos-dest)]
             [height (or height (cell-num-pawns c-dest))])
        (find-path*
         pos-dest (cell-owner c-dest)
         #:move-points 'all ; since it is not for the current turn
         #:stop-at-first? stop-at-first?
         (λ(path cell)
           (and (>= (cell-num-pawns cell) height)
                path)))))

    ;; Finds all paths that can attack the target cell
    (define/public (find-attacked-path* pos-dest [stop-at-first? #f]
                                        #:attacker [attacker #f]
                                        #:can-master-attack? [can-master-attack? #t]
                                        #:test [test (λ(path c)#t)]
                                        )
      (let* ([c-dest         (pos->cell pos-dest)]
             [dest-master?   (cell-has-master? c-dest)]
             ; attacked master is of height 1 only
             [dest-num-pawns (if dest-master? 1 (cell-num-pawns c-dest))]
             [owner          (cell-owner c-dest)]
             [attacker       (or attacker (send owner get-opponent))]
             [move-points    (src-move-points attacker)])
        (find-path*
         pos-dest attacker
         #:stop-at-first? stop-at-first?
         (λ(path cell)
           (let* ([c-master? (cell-has-master? cell)]
                  [c-num-pawns (cell-num-pawns cell)]
                  ; if the master attacks, it must import pawns to match the opponent tower height:
                  [n-import (if c-master? (max (- dest-num-pawns c-num-pawns) 0) 0)])
             (and (or (not c-master?) can-master-attack?)
                  (or c-master? ; the master can attack anything
                      (>= c-num-pawns dest-num-pawns))
                  (<= (+ (* c-num-pawns (sub1 (length path))) 
                         (* 2 n-import)) ; import pawns + move them too (for last move)
                      move-points)
                  (test path cell)
                  path))))))

    ;;;;;;;;;;;;
    ;;; Copy ;;;
    ;;;;;;;;;;;;
    
    (define/public (copy [pl1 #f] [pl2 #f])
      (let ([g (new game% [player1 pl1] [player2 pl2]
                    [player1-name  (and (not pl1) (send player1 get-name))]
                    [player1-class (and (not pl1) (send player1 get-class-name))]
                    [player2-name  (and (not pl2) (send player2 get-name))]
                    [player2-class (and (not pl2) (send player2 get-class-name))]
                    [nb-cells nb-cells]
                    [version version]
                    [no-init? #t])])
        (send g create-matrix)
        (copy-to! g)
        g))
    
    ;; copies this into to-game
    ;; to-game must already have the correct nb-cells,
    ;; its matrix must already exist (with the correct size)
    ;; players must be exist (but are updated),
    (define/public (copy-to! to-game)
      (send to-game init-copied-game 
            player1 player2
            (current-player1?)
            mat winner plies rules
            locked-cells nb-imported nb-exported))
    
    (define/public (init-copied-game cpl1 cpl2 curplay1? cmat 
                                     cwinner cplies crules clocked nbimp nbexp)
      (send player1 copy-init this cpl1 player2)
      (send player2 copy-init this cpl2 player1)
      (set! current-player (if curplay1? player1 player2))
      (matrix-copy! mat cmat)
      (set! winner cwinner)
      (set! plies cplies)
      (set! rules crules)
      (set! locked-cells clocked)
      (set! nb-imported nbimp)
      (set! nb-exported nbexp)
      )
    
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;;; Initializations ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;
    
    (define/public (create-matrix)
      (set-mat (make-matrix nb-cells nb-cells)))
    
    ;; Initialize the board with player cells and board cells
    ;; nb-cell is the width and heigh of the matrix (not the total # of cells)
    (define (init-matrix)
      ; if the matrix does not have the right size, recreate it:
      (unless mat ;(equal? nb-cell (and mat (matrix-nrows mat)))
        (create-matrix))
      
      (let ([mx-one (quotient nb-cells 2)]
            [mx-two (quotient (- nb-cells 1) 2)])
        (matrix-map! 
         mat
         (λ(y x v)
           (let ([pl (cond [(< y 2) player2]
                           [(>= y (- nb-cells 2)) player1]
                           [else #f])]
                 [master? (if (specific-rule? 'master-at-corner)
                              (or (and (= y 0) (= x 0))
                                  (and (= y (- nb-cells 1)) (= x (- nb-cells 1))))
                              (or (and (= y 0) (= x mx-two))
                                  (and (= y (- nb-cells 1)) (= x mx-one))))]
                 )
             (when master?
               (send pl set-master-pos (list x y)))
             ; return:
             (make-cell pl (if pl 1 0) master?)
             )))
        ))
    
    (define/public (init-game [plies '(())])
      (parameterize ([replaying? #t])
        (init-matrix)
        (set! winner #f)
        (set! plies plies)
        (unless (specific-rule? 'no-first-lock-master)
          (add-locked-cell (send player1 get-master-pos)))
        
        (send player1 init-game nb-cells player2)
        (send player2 init-game nb-cells player1)
        
        (set! current-player player2) ; will be switched 
        
        (try-switch-player ; also calls the play method of the current-player
         #t ; force switch
         (if (specific-rule? 'no-first-lock-master)
             '()
             (list (send (send current-player get-opponent) get-master-pos))))))
    
    (init-game plies)
    (unless no-init?
      (replay-game))
      
      ))

(define network-game%
  (class game%
    (init-field [network-id #f])
    
    (inherit-field replaying? winner current-player)
    (inherit last-ply)
    
    (getter/setter network-id)
    
    (define/override (can-current-player-play?)
      (and (not winner)
           (or (replaying?)
               (user=? (send current-player get-name) 
                       ; Make a player-network% player instead!! (and test if current-player)
                       (network:current-user)))))
    
    ;; Sends the last ply to the server
    (define/public (update-network-game)
      (when (and network-id (not (replaying?)))
        (log-debug "Updating network game")
        ; update the game on the server
        (network:update-game network-id (last-ply))))
    
    (define/override (new-ply)
      (update-network-game)
      (super new-ply))
    
    ; Set the id at the end, after update-network-game has been called,
    ; so that this does not trigger an actual server call during init.
    (super-new)
    ))

(set-list-game->game 
 (λ(l [player1-class #f] [player2-class #f]
      #:network-game-id [net-id #f])
  (match l
    [(list version rules nb-cells name1 name2 class1 class2 plies)
     (let* ([class1 (or player1-class class1)]
            [class2 (or player2-class class2)]
            [g (new (if net-id network-game% game%)
                    [version        version]
                    [rules          rules]
                    [nb-cells       nb-cells]
                    [player1-name   name1]
                    [player2-name   name2]
                    [player1-class  class1]
                    [player2-class  class2]
                    [plies          plies])])
       (when net-id
         (send g set-network-id net-id))
       g
     #;(if net-id
         (new network-game%
              [version        version]
              [rules          rules]
              [nb-cells       nb-cells]
              [player1-name   name1]
              [player2-name   name2]
              [player1-class  class1]
              [player2-class  class2]
              [plies          plies]
              [network-id     net-id])
         (new game%
              [version        version]
              [rules          rules]
              [nb-cells       nb-cells]
              [player1-name   name1]
              [player2-name   name2]
              [player1-class  class1]
              [player2-class  class2]
              [plies          plies])))]
    [else (error "Invalid list game" l)])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Fake static class upon current-game ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define/m-setter current-game #f)

(define (network-game?)
  (is-a? current-game network-game%))

;; Define syntactic forms
;; that always uses the current-game
;; -> as if the current game was a static class
(define-syntax-rule (define-game-id-getter name getter)
  (define-syntax name
    (syntax-id-rules ()
      ;[(set! _ pl) (send current-game set-current-player pl)]
      [_ (send current-game getter)])))

(define-syntax-rule (define-game-id-getters ((name getter) ...) name/getter ...)
  (begin
    (define-game-id-getter name getter) ...
    (define-game-id-getter name/getter name/getter) ...))

(define-game-id-getters 
  ([current-player  get-current-player]
   [player-one      get-player1]
   [player-two      get-player2]
   [winner          get-winner]
   [game-plies      get-plies]
   [replaying?      get-replaying?]
   [game-name1      get-name1]
   [game-name2      get-name2]
   [current-name    get-current-name]
   ))

(define-syntax-rule (define-game-caller name caller)
  (define-syntax-rule (name arg (... ...))
    (send current-game caller arg (... ...))))

(define-syntax-rule (define-game-callers ((name caller) ...) name/caller ...)
  (begin
    (define-game-caller name caller) ...
    (define-game-caller name/caller name/caller) ...))

(define-game-callers
  ([current-specific-rules get-rules]
   )
  cell-num-pawns
  cell-has-master?
  cell-owner
  locked-cell?
  free-cell-path-list
  can-current-player-play?
  end-turn-draws?
  player-end-turn
  resign
  can-import?
  import-pawn
  undo
  move
  )

(define (player-must-end-turn?)
  (send (send current-game get-current-player) must-end-turn?))

; Is name the current logged-in player ? (and is it a network game?)
(define (current-user? name)
  (and (network-game?)
       (user=? (network:current-user) name)))
  
;; Is the current logged in player (if logged) the current-player?
(define (user-current-player?)
  (current-user? (send current-player get-name)))


