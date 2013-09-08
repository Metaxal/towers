#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require "frame.rkt"
         "base.rkt"
         "graphics.rkt"
         "replay.rkt"
         "controller.rkt"
         towers-lib/base
         towers-lib/rules
         towers-lib/game
         towers-lib/connection
         towers-lib/preferences
         bazaar/gui/board
         bazaar/gui/list-box-sort
         bazaar/gui/msg-error
         racket/gui/base
         racket/list
         racket/class
         racket/dict
         (only-in framework frame:current-icon)
         )

(provide gui-init gui-show main)

#| *** TODO ***

*** Fixes:
- games list order not kept when list updated
- server: Elo ranking is wrong?!
- menu icon does not launch on amd64 (launching directory problem)
- connection issues on Windows
- install issues on Win7 (+vista?) -> needs administrator rights
- menu launching issue: -> towers.sh : cd /usr/bin \n ./towers ?
- update graphics *before* AI player plays
- EPM for amd64: %requires ia32-libs 
  pb: there is no %architecture directive...
- windows: do not add version name in target directory

*** Requests:
- implement "Remember me" button (save user/pwd)

** Rules:
- handicap: add some pawns to the reserve, even temporarily

** Game, general:
- add comments and title to game
- Undo for opponent ("Your opponent requests an undo. Do you agree?")

** GUI:
- display coordinates on the board?
- reverse player two's reserve box? (he is in front of us)
- make non-official rules more difficult to access (add a preferences checkbox 
  to activate them?)
- if resigned, show resigned player in red?
- show total # of pawns per player (stats of board in a different panel?
- add coordinates to the board
- if click on board while replaying, message-box 
  "You cannot play in replaying mode. Go to the end of the game"
- ajouter une entrée "Network" dans Opponents

** Doc:
- replace "lock" by "freeze" (adequate with blue color)
  Better because more visual, and quite adequate.
- VIDEO (?) (Olivier avait tendance à vouloir déplacer les pions en les faisant sauter par dessus)

** Server:
- download stats

** Website:
- player stats : #wins, #loss, per game size ?
  -> detailed statistics per player !

|#

(define my-frame%
  (class frame% (super-new)
    (define/augment (on-close)
      (on-towers-exit)
      )
    ))

;; Initialize the GUI:
(frame-init
 #:main-frame-code-gen-class my-frame%
 
 #:msg-about-towers-label
 (string-append "Towers - version " current-version)
 
 #:menu-item-new-callback
 (λ _ (new-game-callback))
 #:menu-item-save-callback
 (λ _ (save-game-gui))
 #:menu-item-open-callback
 (λ _ (load-game-gui))
 #:menu-item-exit-callback
 (λ _ (on-towers-exit))
 #:menu-item-about-callback
 (λ _ (send dialog-about show #t))
 #:button-about-ok-callback
 (λ _ (send dialog-about show #f))
 #:menu-item-rules-callback
 (λ _ (rules-callback))
 #:menu-item-website-callback
 (λ _ (website-callback))
 #:menu-item-stats-callback
 (λ _ (stats-callback))

 #:menu-item-undo-callback
 (λ _ (undo-callback))
 
 #:canvas-reserve-one-paint-callback
 (λ(cv dc)(draw-reserve dc player-one tower-one-bmp tower-one-mask))
 #:canvas-reserve-two-paint-callback
 (λ(cv dc)(draw-reserve dc player-two tower-two-bmp tower-two-mask))
 
 #:button-end-turn-callback
 (λ _ (end-turn-callback))
 #:button-resign-callback
 (λ _ (gui-resign))
 #:button-import-callback
 (λ _ (gui-import))
 
 #:menu-item-show-rules-callback
 (λ _ (send frame-rules show (not (send frame-rules is-shown?))))
 
 ; Network:
 #:menu-item-user-callback
 (λ _ (send dialog-user show #t))
 #:button-user-ok-callback
 (λ _  (user-callback))
 #:button-user-cancel-callback
 (λ _ (send dialog-user show #f))

 #:menu-item-create-callback
 (λ _ (create-user-callback))
 
 #:menu-item-games-callback
 (λ _ (update-columns-box-games))
 
 #:menu-item-network-new-game-callback
 (λ _ (show-network-new-game))
 #:button-network-new-game-ok-callback
 (λ _ (validate-opponent-choice))
 #:button-network-new-game-cancel-callback
 (λ _ (send dialog-new-network-game show #f))
 
 
 #:button-new-game-ok-callback
 (λ _ (send dialog-new-game show #f)
   (new-game-gui))
 #:button-new-game-cancel-callback
 (λ _ (send dialog-new-game show #f))
 
 #:text-field-search-opponent-callback
 (λ _ (update-list-box-select-player))
 
 #:button-update-game-callback
 (λ _ (update-network-game))
 #:button-update-game-list-callback
 (λ _ (update-columns-box-games))
 #:cb-games-show-finished-callback
 (λ _ (update-columns-box-games))
 
 ; Replay:
 #:button-first-callback
 (λ _ (go-to-first-ply)
   (replay-current-game))
 #:button-previous-ply-callback
 (λ _ (go-to-previous-ply)
   (replay-current-game))
 #:button-previous-move-callback
 (λ _ (go-to-previous-move)
   (replay-current-game))
 #:button-next-move-callback
 (λ _ (go-to-next-move)
   (replay-current-game))
 #:button-next-ply-callback
 (λ _ (go-to-next-ply)
   (replay-current-game))
 #:button-last-callback
 (λ _ (go-to-last-ply)
   (replay-current-game))

 #:button-undo-callback
 (λ _ (undo-callback))
 
 ; Preferences:
 #:menu-item-preferences-callback
 (λ _ (show-preferences-dialog))
 #:button-preferences-ok-callback
 (λ _ (preferences-callback))
 #:button-preferences-cancel-callback
 (λ _ (send dialog-preferences show #f))
 
 )

(define (gui-init #:read-preferences [pref #t])
  (read-preferences pref)
  (init-connection)
  
  (set-columns-box-games
   (new list-box-sort% [parent frame-games]
        [label ""]
        [style '(single vertical-label)]
        [columns '("Game" "Player 1" "Player 2" "Size" "Last update" "Next Player" "Winner")]
        [comparators (list string<=? string<=? string<=? 
                           (λ(v1 data1 v2 data2)(<= (vector-ref data1 1)
                                                    (vector-ref data2 1)))
                           (λ(v1 data1 v2 data2)(>= (vector-ref data1 4)
                                                    (vector-ref data2 4)))
                           string<=?
                           string<=?
                           )]
        [callback (λ(lbc evt)
                    (when (equal? (send evt get-event-type) 'list-box)
                      (define game-id (vector-ref (send lbc get-selection-data) 0))
                      (with-error-to-msg-box (load-network-game game-id))))]))
  (send* columns-box-games
    (set-column-width 3 50 10 200)
    (set-column-width 1 70 10 200)
    (set-column-width 2 70 30 200)
    (set-column-width 3 50 10 50)
    (set-column-width 4 150 50 280)
    (set-column-width 5 90 30 200)
    (set-column-width 6 70 30 200))
  
  (set-rules-check-boxes-dict
   (dict-map rules-dict
             (λ(r str)
               (cons r (new check-box% [parent vp-new-game-rules]
                            [label (rule->line-string r)]
                            [value #f])))))
  
  ;; Create a board using the game matrix and
  ;; put it inside the main-frame
  (set-board 
   (new board% 
        [parent panel-board]
        [num-cell-x 10]
        [cell-dx CELL-DX]
        [on-left-down  board-left-down]
        [on-left-up    board-left-up]
        [on-right-down board-right-down]
        [on-right-up   board-right-up]
        [on-mouse-move board-mouse-move]
        ))
  
  (set-board-cell-pic)
  
  (controller-init)
  
  (update-frame-labels)
  (for-each set-frame-icon
            (list main-frame frame-games frame-rules)))

(define (gui-show)
  (send main-frame show #t))

(define (main cmd)
  (case cmd
    [(init) (gui-init)]
    [(show) (gui-show)]))
