#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide player-alpha-beta-gui%)

(require towers-lib/player-base
         towers-lib/player-alpha-beta
         towers-lib/game
         "base.rkt"
         "frame.rkt"
         "graphics.rkt"
         racket/gui/base
         racket/class
         )

(define-player-class player-alpha-beta-gui% "Alpha-Beta"
  (class* player-alpha-beta% (player-gui<%>)
    (super-new)

    (inherit-field depth-max game)
    (inherit say stop-search get-nb-move-remaining get-nb-move-total)

    (define diag (new dialog% [parent main-frame] [label "Difficulty"]))
    (define lb-difficulty (new choice% [parent diag]
                               [label "Choose a difficulty level:"]
                               [choices (build-list 7 (λ(n)(number->string (+ n 1))))]))
    (define bt-ok (new button% [parent diag]
                       [label "Ok"]
                       [callback (λ _ (send diag show #f))]))


    (define frame-search (new frame% [parent main-frame]
                              [label "Searching..."]))
    (set-frame-icon frame-search)
    (define search-gauge (new gauge% [parent frame-search]
                              [range 100]
                              [label "Searching..."]
                              [style '(horizontal vertical-label)]))
    ; TODO: gauge...
    (define bt-stop-search (new button% [parent frame-search]
                                [label "Stop search now!"]
                                [callback (λ _ (stop-search))]
                                ))

    ;(define/override (say str)
    ;  (message-box "Towers" str))

    (define/override (update-view)
      (when (eq? current-game game)
        (say "Updating view")
        (update)
        (sleep/yield .5)))

    (define/override (on-play-move)
      (send frame-search show #t) ; thread because a dialog% locks the thread
      (thread (λ()(super on-play-move)
                (send frame-search show #f)
                ))
      (let loop ()
        (when (send frame-search is-shown?)
          (sleep/yield .3)
          (send search-gauge set-range (get-nb-move-total))
          (send search-gauge set-value (- (get-nb-move-total) (get-nb-move-remaining)))
          (loop)))
      )


    ; asks for difficulty level
    (send diag show #t)
    (set! depth-max (+ 1 (send lb-difficulty get-selection)))

    ))