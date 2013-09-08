#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require towers-lib/base
         towers-lib/game
         towers-lib/rules
         towers-lib/player
         (prefix-in network: towers-lib/connection)

         "base.rkt"
         "frame.rkt"
         bazaar/define
         bazaar/values
         bazaar/gui/bitmaps
         racket/gui/base
         racket/class
         racket/list
         )

(provide (all-defined-out))

(define (gui-can-play?)
  (and (player-human? current-player) (can-current-player-play?) (not replaying?)))


(define (get-tower-bmp player master?)
  (if (eq? player player-one)
      (if master? tower-one-master-bmp tower-one-bmp)
      (if master? tower-two-master-bmp tower-two-bmp) 
      ))
(define (get-tower-mask player master?)
  (if (eq? player player-one)
      (if master? tower-one-master-mask tower-one-mask)
      (if master? tower-two-master-mask tower-two-mask)))


(define (set-board-cell-pic)
  (send board set-cell-pic 
        ; share bmp/bmp-dc to avoid creating it for each cell:
        (let* ([bmp (make-object bitmap% CELL-DX CELL-DY)]
               [bmp-dc (make-object bitmap-dc% bmp)])
          (λ(i j c)
            (let* ([bk        (modulo (+ i j) 2)] ; background
                   [nbp       (cell-num-pawns c)]
                   [owner     (cell-owner c)]
                   [master?   (cell-has-master? c)]
                   [pos       (list j i)]
                   [selected? (equal? selected-cell pos)]
                   )
              (send bmp-dc draw-bitmap 
                    (if (= bk 0) black-cell-bmp white-cell-bmp)
                    0 0)
              (let ([bmp-over 
                     (cond [selected? selected-cell-bmp]
                           [(and master? (send owner master-attacked?) (not winner))
                            ;(printf "Master in danger!\n")
                            (if (locked-cell? pos)
                                danger-locked-cell-bmp
                                master-danger-cell-bmp)]
                           [(locked-cell? pos) locked-cell-bmp]
                           [else #f])])
                (when bmp-over
                  (draw-bitmap/mask bmp-dc bmp-over 0 0)))

              (when owner
                (if selected?
                    (let ([nbp-draw (- nbp nb-selected-pawns)])
                      (when (> nbp-draw 0)
                        (draw-tower bmp-dc owner master? nbp-draw)))
                    (draw-tower bmp-dc owner master? nbp))) ; c)))
              ; return value:
              bmp))
          )))

(define font-tower-number
  (send the-font-list find-or-create-font
        16    ;  size : (integer-in 1 255)
        'default ;  family: (one-of/c 'default 'decorative 'roman 'script
        ;                    'swiss 'modern 'symbol 'system)
        'normal ;  style : (one-of/c 'normal 'italic 'slant)
        'normal ;  weight : (one-of/c 'normal 'bold 'light)
        #f ;  underline? : any/c = #f
        'default ;  smoothing: (one-of/c 'default 'partly-smoothed 'smoothed 'unsmoothed) = 'default
        #t ;  size-in-pixels? : any/c = #f
        ))

;; Draws text=num centered on (x y)
(define (draw-tower-number dc color num x y)
  (let ([str (number->string num)])
    (send dc set-font font-tower-number) ; to compute lengths correctly
    (let-values ([(w h a b) (send dc get-text-extent str)])
      (let ([x-start (- x (quotient w 2))]
            [y-start (- y (quotient h 2))])
        ; background, for contrast
        (send dc set-text-foreground white)
        (send dc draw-text str (- x-start 1) (- y-start 1))
        (send dc draw-text str (- x-start 1) (+ y-start 1))
        (send dc draw-text str (+ x-start 1) (- y-start 1))
        (send dc draw-text str (+ x-start 1) (+ y-start 1))
        ; foreground
        (send dc set-text-foreground black);color)
        (send dc draw-text str x-start y-start)
        ))))

;; Main function to call to draw a tower
(define (draw-tower dc player master? num 
                    #:with-mask [with-mask #t]
                    #:x [x 0] #:y [y 0]
                    )
  (let ([bmp (get-tower-bmp player master?)])
  (draw-bitmap/mask dc
        bmp
        x y
        (and with-mask (send bmp get-loaded-mask))
        ;(and with-mask (get-tower-mask player master?))
        )
  ; draw tower height number on top of it:
  (when (> num 1)
    (draw-tower-number dc (if (eq? player player-one) color-one color-two)
                       num (+ x HALF-CELL-DX) (+ y HALF-CELL-DY)))
  ))
  


(define (draw-board)
  (send board draw)
  (send canvas-reserve-one refresh)
  (send canvas-reserve-two refresh)
  (update-msg-ply-number)
  )
    
(define reserve-buffer #f)
(define reserve-buffer-dc #f)

(define (draw-current-reserve [use-nb-move-points 0])
  ; make a new buffer if the previous one is not adequate:
  (let ([cv-w (send canvas-reserve-one get-width)]
        [cv-h (send canvas-reserve-one get-height)]
        [buf-w (and reserve-buffer (send reserve-buffer get-width))])
    (unless (and reserve-buffer (= buf-w cv-w))
      ;(printf "draw-current-reserve: make-object bitmap%\n")
      (set! reserve-buffer (make-object bitmap% cv-w cv-h))
      (set! reserve-buffer-dc (make-object bitmap-dc% reserve-buffer))))
  ; draw in that buffer, then paste it in the actual canvas
  (if (equal? current-player player-one)
      (begin (draw-reserve reserve-buffer-dc player-one tower-one-bmp tower-one-mask
                           use-nb-move-points)
             (send (send canvas-reserve-one get-dc) draw-bitmap reserve-buffer 0 0)
             ;(send canvas-reserve-one refresh)
             )
      (begin (draw-reserve reserve-buffer-dc player-two tower-two-bmp tower-two-mask
                    use-nb-move-points)
             (send (send canvas-reserve-two get-dc) draw-bitmap reserve-buffer 0 0))
      ))
      

;; use-nb-move-points: remove some move-points from the remaining points.
;; does not test for consistency!
(define (draw-reserve dc player tower-bmp tower-mask [use-nb-move-points 0])
  ; If current player, draw background to yellow:
  (send dc set-background 
        (cond [(eq? winner player) 
               win-green]
               ;(send the-color-database find-color "Medium Spring Green")]
               ;green]
              [winner white];black] ; if there is a winner, but not us
              [(eq? current-player player) light-yellow]
              [else white])
        )
  (send dc clear)
  
  (let* ([mvp (- (send player get-move-points) use-nb-move-points)]
         [nbres (send player get-num-pawns-reserve)]
         [used-points (- nbres mvp)]
         [w (first (values->list (send dc get-size)))]
         )
    (for ([i (in-range mvp)])
      (draw-bitmap/mask dc tower-bmp
                        (* i 8) 0
                        tower-mask))
    (when (> mvp 0)
      (draw-tower-number dc (if (eq? player player-one) color-one color-two)
                         mvp 
                         (+ (* (- mvp 1) 8) HALF-CELL-DX) HALF-CELL-DY))
    
    (for ([i (in-range used-points)])
      (draw-bitmap/mask dc tower-bmp
                        (- w (* i 8) CELL-DX) 0
                        tower-mask))
    (when (> used-points 0)
      (draw-tower-number dc (if (eq? player player-one) color-one color-two)
                         used-points 
                         (- w (* (- used-points 1) 8) HALF-CELL-DX) HALF-CELL-DY))
    )
  )

(define (resize-main-frame)
  (send main-frame resize 
        (send main-frame min-width)
        (send main-frame min-height)))     

(define (update-msg-ply-number)
  (let ([ply-num-total (length (game-plies current-game))])
    (send* message-ply-number 
      (set-label
       (format "~a/~a"
               (if replaying? replay-current-ply-num ply-num-total)
               ply-num-total
               ))
      (refresh)
      )))

(define (update)
  (update-game-buttons)
  (draw-board)
  (when winner
    (message-box "End of Game"
                 (if (equal? winner 'draw)
                     "This game is a draw."
                     (string-append (send winner get-name) " has won!"))))
  )

(define (set-frame-icon frame)
  (send frame set-icon 
        (make-object bitmap% frame-icon-path 'png)
        #f;(make-object bitmap% frame-icon-mask-path); #f
        'both))


(define (update-names)
  (send message-player-one-name set-label 
        (string-append game-name1 " (" (send player-one get-class-name) ")"))
  (send message-player-two-name set-label 
        (string-append game-name2 " (" (send player-two get-class-name) ")"))
  )

(define (update-game-buttons)
  (let ([can-play? (gui-can-play?)]
        [must-end? (player-must-end-turn?)])
    (send button-update-game enable (and network-game-id (not winner) (not replaying?) (not can-play?)))
    (send button-end-turn    set-label (cond [(end-turn-draws?) draw-game-bmp]
                                             [must-end? end-turn-salient-bmp]
                                             [else end-turn-bmp]))
    (send button-end-turn    enable can-play?)
    (send button-import      enable (and can-play? (can-import?)));(not must-end?)))
    (send button-resign      enable can-play?)
    (send button-undo        enable can-play?)
    ))

(define (update-frame-rules)
  (when current-game
    (let ([rules (current-specific-rules)]
          [ed (send text-field-rules get-editor)])
      (send ed erase)
      (if (empty? rules)
          (send ed insert "This game uses the official rules.\n")
          (for-each (λ(r)(when r
                           (send ed insert 
                                 (string-append "- " (rule->string r) "\n"))))
                    rules))
      (send frame-rules show (not (empty? rules)))
      )))
  
(define (update-frame-labels) 
  (let* ([log (network:current-user)]
         [lab (λ(f t)(send f set-label
                           (string-append 
                            t (if log (string-append " - " log) ""))))]
         )
    (lab main-frame "Towers")
    (lab frame-games "Games")
    ))
