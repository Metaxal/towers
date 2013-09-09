#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require "player-alpha-beta-gui.rkt"
         "frame.rkt"
         "base.rkt"
         "graphics.rkt"
         towers-lib/base
         towers-lib/game
         towers-lib/file
         (prefix-in network: towers-lib/connection)
         ; All player modules must be required for them to appear in the new game dialog
         towers-lib/player-base
         towers-lib/player
         towers-lib/player-ai1

         bazaar/mutation
         bazaar/gui/board
         bazaar/gui/bitmaps
         bazaar/gui/float-box
         bazaar/gui/msg-error
         racket/gui/base
         racket/class
         racket/dict
         racket/list
         racket/match
         racket/date
         net/sendurl
         )

(define (on-towers-exit)
  (send update-network-game-timer stop)
  (send main-frame show #f)
  (send frame-rules show #f)
  (send frame-games show #f)
  )

(define (send-towers-url sub-url)
  (send-url (string-append (network:server-address) sub-url)))

(define (website-callback)
  (send-towers-url ""))
(define (stats-callback)
  (send-towers-url "/statistics"))

(define (rules-callback)
  (send-url/file manual-html-path))

;;;;;;;;;;;;;;;;;;;;;;;
;;; Game Controller ;;;
;;;;;;;;;;;;;;;;;;;;;;;

(define (controller-init)
  (date-display-format 'iso-8601) ; "2010-06-15 19:25:16"
  
  (set-auto-end-turn)

  ;; Initialize the game:
  (play-game-gui
   (new game% [nb-cells 10] ; 5 -> 10
        [player1-name "Player one"]
        [player1-class "Human"]
        [player2-name "Player two"]
        [player2-class "Human"]
        [network-game-id #f]
        [rules '()])
   #f))

(define (new-game-gui)
  (let-values ([(net? me-class me opp-class opponent)
                (apply values new-game-gui-args)])
    (and me opponent
         (let* ([nb-cells (+ 5 (send choice-game-size get-selection))]
                [first-player? (not (equal? 1 (send radio-box-first-player get-selection)))]
                [rules (filter (λ(x)x)
                               (dict-map rules-check-boxes-dict
                                         (λ(r cb)(and (send cb get-value) r))
                                         ))]
                [g (new game% [nb-cells nb-cells]
                        [player1-name  (if first-player? me opponent)]
                        [player1-class (if first-player? me-class opp-class)]
                        [player2-name  (if first-player? opponent me)]
                        [player2-class (if first-player? opp-class me-class)]
                        [rules rules])]
                [net-id (and net? (network:new-game g))]
                )
           (when net?
             (update-columns-box-games))
           (play-game-gui g net-id)
           (set! current-file #f)
           ))))

;; Plays a given game and adapts the gui to it.
(define (play-game-gui game net-id
                       [nb-plies #f] [nb-moves #f]
                       #:update-rules [update-rules #t]
                       #:replay? [replay? #f])
  (with-error-to-msg-box
   (send game set-network-game-id net-id)
   (send game replay-game nb-plies nb-moves)
   (set-current-game game)
   (send board set-matrix (send current-game get-mat))
   (update-names)
   (when update-rules
     (update-frame-rules))
   (resize-main-frame)
   (update-game-buttons)
   (draw-board)
   ))

;;;;;;;;;;;;;;;
;;; Actions ;;;
;;;;;;;;;;;;;;;

(define (end-turn-callback)
  (when (and (gui-can-play?)
             (or (not (end-turn-draws?))
                 (equal? 'yes
                        (message-box "Draw game?" 
                                     "Passing your turn will draw this game.\nAre you sure you want to pass?" 
                                     main-frame
                                     '(yes-no caution)))))
    (player-end-turn)
    (update)
    ))

(define (gui-resign)
  (when (and (gui-can-play?)
             (equal? 'yes 
                     (message-box "Resign?" 
                                  "Are you sure you want to resign this game?"
                                  #f '(caution yes-no))))
    (resign)
    (update)))

(define (gui-import)
  (when (gui-can-play?)
    (import-pawn 1)
    (update)
    ))

(define (undo-callback)
  (when (gui-can-play?)
    (undo)
    (play-game-gui current-game network-game-id #:update-rules #f)
    ))

;;;;;;;;;;;;;;;;;;;;;
;;; File Handling ;;;
;;;;;;;;;;;;;;;;;;;;;

(define current-file #f)

(define (save-game-gui)
  (let ([file (or current-file
                  (put-file "Save Towers Game"
                            main-frame
                            #f #f "twr" '()
                            '(("Towers Game File" "*.twr")("Any" "*.*"))))])
    (when file
      (save-current-game file))))

(define (load-network-game game-id [update-rules #t])
  (with-error-to-error-port
   (define g
     (match (network:get-game game-id)
       [(list version rules nb-cells name1 name2 class1 class2 plies)
        (new game%
             [version version]
             [rules rules]
             [nb-cells nb-cells]
             [player1-name  name1]
             [player2-name  name2]
             [player1-class (if (current-user? name1) "Human" "Network")]
             [player2-class (if (current-user? name2) "Human" "Network")]
             [plies plies]
             )]
       [else (error (format "Cannot read game ~a\n" game-id))
             #f]))
     (when g
       (play-game-gui g game-id #:update-rules update-rules))))

(define (load-game-gui)
  (let ([file (get-file "Load Towers Game"
                        main-frame
                        #f #f "twr" '()
                        '(("Towers Game File" "*.twr")("Any" "*.*")))])
    (when file
      (play-game-gui (load-game file) #f)
      )))

; ***********************************
; * * * * Graphics Controller * * * *
; ***********************************


(define (select-cell xc yc [nbp #f])
  (let* ([c (board-ref board xc yc)]
         [pos (list xc yc)]
         [nbp (or nbp (cell-num-pawns c))]
         [owner (cell-owner c)]
         )
    (when (and (not (locked-cell? pos))
               (eq? current-player owner))
      (set-selected-cell pos)
      (set-nb-selected-pawns nbp)
      )))
  
;; Selects a cell, 
;; or moves the tower
(define (board-left-down xc yc)
  (with-error-to-msg-box
   (when (gui-can-play?)
     (select-cell xc yc)
     (update)
     )))

(define (board-left-up xc yc)
  (with-error-to-msg-box
   (when (and (gui-can-play?)
              selected-cell)
     (unless (equal? selected-cell (list xc yc))
       (move (first selected-cell) (second selected-cell) xc yc nb-selected-pawns)
       (when (and (auto-end-turn) (player-must-end-turn?)
                  (player-human? current-player))
         (player-end-turn))
       )
     (set-selected-cell #f)
     (update)
     )))

(define (board-right-down xc yc)
  (with-error-to-msg-box
   (when (gui-can-play?)
     (select-cell xc yc 1)
     (update)
     )))

(define board-right-up board-left-up)

; SHOULD be in graphics.rkt
(define (draw-cell-path dc cells)
  (when cells
    (for ([pos (in-list cells)])
      (draw-bitmap/mask dc selected-cell-bmp
                        (send board xc->x (first pos))
                        (send board yc->y (second pos))
                        ))))
  

(define (board-mouse-move x y)
  ; the random part is here to filter some events to make it faster
  (when (and (= 0 (random 2))
             selected-cell) ; which is in fact selected-cell-pos...
    (let* ([cx  (send board x->xc x)]
           [cy  (send board y->yc y)]
           [scx (first selected-cell)]
           [scy (second selected-cell)]
           [sc  (board-ref board scx scy)]
           [master? (and (equal? (cell-num-pawns sc) 
                                              nb-selected-pawns)
                                      (cell-has-master? sc))]
           [required-move-points
            (move scx scy cx cy nb-selected-pawns #:test? #t)])
        (draw-current-reserve (or required-move-points 0))
      ; highlight the path from selected cell to current cell:
      (when (or required-move-points
                (equal? (list cx cy) selected-cell))
        (send board draw-over
              (λ(dc)
                (draw-cell-path dc (cons (list cx cy) (free-cell-path-list scx scy cx cy)))
                
                ; VERY Strange!
                ; I first used a buffer to store the image 
                ; instead of recreating it each time.
                ; But because (somehow) of the mask, it was taking a lot of
                ; time to render! Weirder: this was not true with the master...
                ; Fortunately, if I take the "redraw-it-each-time" version,
                ; it works smoothly...
                (draw-tower dc current-player 
                            master? nb-selected-pawns 
                            #:x (- x HALF-CELL-DX)
                            #:y (- y HALF-CELL-DY)
                            )
                ;                ; The following makes the above drawing very slow!!
                ;                ; Weird: not true if the master is being moved!
                ;                (draw-bitmap/mask dc 
                ;                                  selected-tower-bmp 
                ;                                  (- x HALF-CELL-DX)
                ;                                  (- y HALF-CELL-DY)
                ;                                  )
                )))
        )))


(define (starred-current-user user)
  (if (user=? user (network:current-user))
      (string-append "* " user)
      user))

;; Returns the current-user
;; If none, asks for one.
;; Returns #f if the user cancels.
(define (network-current-user-or-ask)
  (unless (network:current-user)
    (send dialog-user show #t))
  (network:current-user))

(define (update-columns-box-games)
  (let ([user (network-current-user-or-ask)]
        [show-finished? (send cb-games-show-finished get-value)])
    (when user
      (send frame-games set-label
            (string-append "Games - " user))
      ; fill the list box with games
      (let ([games (if show-finished? (network:get-game-list) (network:get-current-game-list))])
        (send columns-box-games clear)
        (for-each (λ(g)
                    (match g
                      [(vector #;list id size pl1 pl2 secs next-player p-winner)
                       (send columns-box-games append
                             (list (number->string id) pl1 pl2 
                                   (number->string size)
                                   (date->string (seconds->date secs) #t)
                                   (if p-winner "" (starred-current-user next-player))
                                   (or (starred-current-user p-winner) "")
                                   )
                             g #;(vector->list g))
                       ]))
                  games)
        (if (send frame-games is-shown?)
            (send frame-games refresh)
            (send frame-games show #t))
        ))))


(define (user-callback)
  (let ([l (send text-field-user get-value)]
        [p (send text-field-password get-value)])
    (with-handlers ([exn:fail? (λ(e)
                                 (displayln e)
                                 (network:current-user #f)
                                 (message-box "Error" "Incorrect user or password" 
                                              #f '(ok caution)))])
      (network:set-user-password l p)
      (or (network:check-authentication)
          (error "Authentication failed"))
      (update-columns-box-games)
      (send dialog-user show #f)
      ))
  (update-frame-labels)
  )

(define (create-user-callback)
  (send-towers-url "/create-user.html"))

(define player-names '())

(define (update-list-box-select-player)
  (send list-box-opponent clear)
  (let* ([txt (send text-field-search-opponent get-value)]
         [net? (first new-game-gui-args)]
         [players (filter (λ(p)(regexp-match (string-append "(?i:" (regexp-quote txt) ")") p))
                          player-names)]
         [players (if net?
                      (sort (remove (network:current-user) players string-ci=?) string<?)
                      players)])
    (for-each (λ(p)(send list-box-opponent append p))
              players)
    ))
    
;; New network game
(define (show-network-new-game)
  (when (network-current-user-or-ask)
    (set! new-game-gui-args (list #t "Human" (network:current-user)))
    
    (set! player-names (network:get-players))
    
    (send text-field-search-opponent set-value "")
    (update-list-box-select-player)
    
    (send dialog-new-network-game show #t)
    ))

(define new-game-gui-args #f)

;; New local game
(define (new-game-callback)
  (set! new-game-gui-args (list #f "Human" "Player 1"))
  (set! player-names (get-player-gui-classes))
  (send text-field-search-opponent set-value "")
  (update-list-box-select-player)
  (send dialog-new-network-game show #t))

(define (validate-opponent-choice)
  (let ([opponent (send list-box-opponent get-string-selection)]
        [net? (first new-game-gui-args)])
    (if opponent
        (begin
          (send dialog-new-network-game show #f)
          (append! new-game-gui-args 
                   (if net?
                       (list "Network" opponent)
                       (list opponent "Player 2")))
          (show-dialog-new-game)
          )
        (message-box "Choose opponent" "Please select an opponent" dialog-new-network-game '(ok))
        )))


(define (show-dialog-new-game)
  (send msg-new-game-players
        set-label (string-append 
                   (third new-game-gui-args)
                   " VS "
                   (fifth new-game-gui-args)
                   ))
  (send dialog-new-game show #t)
  )

(define fb-opponent-has-played
  (new float-box% [message "Towers: Your opponent has played."]
       [icon icon-bmp]
       [style '(ok-cancel)]
       [ok-callback (λ()(send main-frame focus))]
       ))

(define (update-network-game)
  (when (and network-game-id
             (not (user-current-player?))) ; no need to update if it is our turn to play
    (load-network-game network-game-id #f)))

(define (timer-update-callback)
  (unless (and main-frame (send main-frame is-shown?))
    (send update-network-game-timer stop)
    (set! update-network-game-timer #f)
    )
  (when (and update-network-game-timer
             network:current-user
             (send frame-games is-shown?)
             (send prefs get 'auto-update)
             )
    (update-columns-box-games))
  (when (and network-game-id
             (send prefs get 'auto-update)
             (not (user-current-player?))
             (not replaying?))
      (update-network-game)
      (when (and (user-current-player?)
                 (send prefs get 'auto-update-notify))
        (send fb-opponent-has-played show #t)
        )))

(define update-network-game-timer 
  (new timer% [notify-callback timer-update-callback]
       [interval 60000]))


;;;;;;;;;;;;;;;;;;;
;;; Preferences ;;;
;;;;;;;;;;;;;;;;;;;

(define (set-auto-end-turn)
  (auto-end-turn (send prefs get 'auto-end-turn)))

(define (prefs-cb-dict)
  `((,cb-prefs-auto-update       . auto-update)
    (,cb-prefs-auto-update-notif . auto-update-notify)
    (,cb-prefs-auto-end-turn     . auto-end-turn)
    ))

(define (show-preferences-dialog)
  (for ([(cb pref) (in-dict (prefs-cb-dict))])
    (send cb set-value (send prefs get pref)))
  (send dialog-preferences show #t)
  )

(define (preferences-callback)
  ; save preferences from file
  (for ([(cb pref) (in-dict (prefs-cb-dict))])
    (send prefs set pref (send cb get-value)))
  (send prefs save)
  (set-auto-end-turn)
  (send dialog-preferences show #f)
  )
