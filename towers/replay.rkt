#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require "base.rkt"
         "controller.rkt"
         towers-lib/base
         towers-lib/game
         bazaar/define
         racket/gui/base
         racket/class
         )

;;;;;;;;;;;;;;;;;
;;; Replaying ;;;
;;;;;;;;;;;;;;;;;

(define (init-ply-move-number)
  (unless replaying?
    (go-to-last-ply)))

(define/provide (go-to-first-ply)
  (go-to-last-ply)
  (set-replay-current-ply-num 1)
  (set-replay-current-move-num 0)
  )

;; For a given ply number, tells how many moves there is
;; for the current-game-saved (supposed to be set)
(define/provide (get-nb-moves-saved ply-num)
  (if (and (> ply-num 0)
           (<= ply-num (length game-plies)))
      (length (list-ref game-plies (sub1 ply-num)))
      0))

(define/provide (go-to-last-ply)
  (set-replay-current-ply-num (length game-plies))
  (set-replay-current-move-num (get-nb-moves-saved replay-current-ply-num))
  )

(define/provide (go-to-next-ply)
  (init-ply-move-number)
  (if (< replay-current-ply-num (length game-plies))
      (begin
        (++replay-current-ply-num)
        (set-replay-current-move-num 0))
      ; else
      (go-to-last-ply))
  )

(define/provide (go-to-previous-ply)
  (init-ply-move-number)
  (if (<= replay-current-ply-num 1)
      (set-replay-current-move-num 0) ; just go at the beginning of the ply
      (begin
        (--replay-current-ply-num)
        (set-replay-current-move-num 0)
        ;(set! replay-current-move-num
        ;      (get-nb-moves-saved replay-current-ply-num))
        ))
  )

(define/provide (go-to-next-move)
  (init-ply-move-number)
  (if (< replay-current-move-num
         (get-nb-moves-saved replay-current-ply-num))
      (++replay-current-move-num)
      (go-to-next-ply))
  )

(define/provide (go-to-previous-move)
  (init-ply-move-number)
  (when (or (> replay-current-move-num 0)
            (> replay-current-ply-num 1))
    (--replay-current-move-num))
  (when (and (<= replay-current-move-num 0)
             (> replay-current-ply-num 1))
    (--replay-current-ply-num)
    (set-replay-current-move-num
          (get-nb-moves-saved replay-current-ply-num)))
  )

(define/provide (replay-current-game)
  ; save the full current game in case we replay a part of the current game
  (play-game-gui current-game
                 replay-current-ply-num
                 replay-current-move-num
                 #:update-rules #f
                 #:replay? #t)
  )

