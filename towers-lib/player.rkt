#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide player%
         player?
         player-human%
         player-human?
         player-server-test%
         find-player-class
         define-player-class
         )

(require "player-base.rkt"
         racket/class
         )

(define player%
  (class player-base% (super-new)
    ))

;; Human player.
;; Just a mock to have a type (+ some methods)
;; Move handling is done in towers-gui-graphic.rkt
(define-player-class player-human% "Human"
  (class* player% (player-gui<%>)
    (super-new)
    ))
(define (player-human? p)
  (is-a? p player-human%))

;; Just for the type, different from human.
;; This class should be used for remote players.
(define-player-class player-network% "Network"
  (class player% (super-new)
    ))
(define (player-network? p)
  (is-a? p player-network%))

;; A player with nothing in for testing already played games
(define-player-class player-server-test% "ServerTest"
  (class player% (super-new)
    ))
