#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require towers-lib/base
         bazaar/getter-setter
         bazaar/mutation
         bazaar/preferences
         racket/gui/base
         racket/class
         racket/runtime-path
         (for-syntax racket/base)
         )

;;; Constant definitions

(define CELL-DX 48)
(define CELL-DY CELL-DX)
(define HALF-CELL-DX (quotient CELL-DX 2))
(define HALF-CELL-DY (quotient CELL-DY 2))

(define-runtime-path manual-html-path
  (build-path "docs" "manual.html"))

(define-for-syntax img-path "img")
(define            img-path "img")

(define-runtime-path frame-icon-path
  (build-path img-path "icon.png"))

(define-runtime-path-list
  board-pngs
  (map (λ(str)(build-path img-path (string-append str ".png")))
       '("black-cell" "white-cell" "selected-cell" "locked-cell" "master-danger-cell"
                      "danger-locked-cell"
                      "player-one" "player-one-master"
                      "player-two" "player-two-master"
                      "end-turn-48" "end-turn-salient-48" "draw-game-48"
                      "icon"
                      ))
  )

(define-values
   (black-cell-bmp
    white-cell-bmp
    selected-cell-bmp
    locked-cell-bmp
    master-danger-cell-bmp
    danger-locked-cell-bmp
    tower-one-bmp
    tower-one-master-bmp
    tower-two-bmp
    tower-two-master-bmp
    end-turn-bmp
    end-turn-salient-bmp
    draw-game-bmp
    icon-bmp
    )
   (apply values
          (map (λ(path)(make-object bitmap% path 'png/mask))
               board-pngs)))

(define-values
  (tower-one-mask
   tower-one-master-mask
   tower-two-mask
   tower-two-master-mask)
  (apply values
         (map (λ(bmp)(send bmp get-loaded-mask))
              (list tower-one-bmp
                    tower-one-master-bmp
                    tower-two-bmp
                    tower-two-master-bmp)))
  )

(define player-turn-bmp (make-bitmap CELL-DX CELL-DY))

(define color-one    (make-color 180 0 0))
(define color-two    (make-color 0   0 140))

(define white        (make-color 255 255 255))
(define black        (make-color 0   0   0))
(define yellow       (make-color 255 255 0))
(define light-yellow (make-color 255 192 96))
(define green        (make-color 0   255 0))
(define win-green    (make-color 0   130 30))


(define/m-setter columns-box-games #f)

(define/m-setter rules-check-boxes-dict #f)

(define/m-setter board #f)

(define/m-setter nb-selected-pawns 0)

(define/m-setter selected-cell #f)

(define/m-setter replay-current-ply-num 1)
(define (++replay-current-ply-num)
  (++ replay-current-ply-num))
(define (--replay-current-ply-num)
  (-- replay-current-ply-num))

(define/m-setter replay-current-move-num 0)
(define (++replay-current-move-num)
  (++ replay-current-move-num))
(define (--replay-current-move-num)
  (-- replay-current-move-num))

(define auto-end-turn (make-parameter #f))

;;;;;;;;;;;;;;;;;;;
;;; Preferences ;;;
;;;;;;;;;;;;;;;;;;;

(send* prefs
  (set 'auto-update         #t #:save? #f)
  (set 'auto-update-notify  #t #:save? #f)
  (set 'auto-end-turn       #t #:save? #f))

