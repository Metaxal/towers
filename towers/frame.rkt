#lang racket/base

;;==========================================================================
;;===                Code generated with MrEd Designer 3.11              ===
;;===              https://github.com/Metaxal/MrEd-Designer              ===
;;==========================================================================

;;; Call (frame-init) with optional arguments to this module

(require
 framework
 racket/gui/base
 racket/list
 racket/class
 )

(provide frame-init
         main-frame
         dialog-about
         dialog-user
         text-field-user
         text-field-password
         frame-games
         cb-games-show-finished
         frame-rules
         text-field-rules
         dialog-new-game
         msg-new-game-players
         choice-game-size
         radio-box-first-player
         vp-new-game-rules
         dialog-new-network-game
         list-box-opponent
         text-field-search-opponent
         button-network-new-game-ok
         button-network-new-game-cancel
         dialog-preferences
         cb-prefs-auto-end-turn
         cb-prefs-auto-update
         cb-prefs-auto-update-notif
         tf-prefs-user
         tf-prefs-pwd
         tf-server-address
         tf-server-port
         tf-server-root-path
         tf-server-version
         button-undo
         message-ply-number
         horizontal-panel-all
         button-update-game
         button-import
         button-end-turn
         button-resign
         message-player-two-name
         canvas-reserve-two
         panel-board
         canvas-reserve-one
         message-player-one-name
         dialog-create-user
         tf-new-user
         tf-new-pwd
         tf-new-email)

(define (label-bitmap-proc l)
  (let ((label (first l)) (image? (second l)) (file (third l)))
    (or (and image?
             (or (and file
                      (let ((bmp (make-object bitmap% file 'unknown/mask)))
                        (and (send bmp ok?) bmp)))
                 "<Bad Image>"))
        label)))

(define (list->font l)
  (with-handlers
   ((exn:fail?
     (λ (e)
       (send/apply
        the-font-list
        find-or-create-font
        (cons (first l) (rest (rest l)))))))
   (send/apply the-font-list find-or-create-font l)))

(define frame #f)
(define main-frame #f)
(define dialog-about #f)
(define horizontal-pane-3542 #f)
(define message-about-image #f)
(define msg-about-towers #f)
(define message-22281 #f)
(define message-3520 #f)
(define pane-24649 #f)
(define message-22222 #f)
(define message-24602 #f)
(define message-3865 #f)
(define message-4045 #f)
(define pane-29300 #f)
(define message-29351 #f)
(define message-29464 #f)
(define button-about-ok #f)
(define menu-bar #f)
(define menu-game #f)
(define menu-item-new #f)
(define menu-item-open #f)
(define menu-item-save #f)
(define separator-menu-item-9516 #f)
(define menu-item-show-rules #f)
(define separator-menu-item-3191 #f)
(define menu-item-exit #f)
(define menu-network #f)
(define menu-item-user #f)
(define menu-item-create #f)
(define menu-item-games #f)
(define menu-item-network-new-game #f)
(define separator-menu-item-3877 #f)
(define menu-item-stats #f)
(define menu-edit #f)
(define menu-item-undo #f)
(define separator-menu-item-3841 #f)
(define menu-item-preferences #f)
(define menu-help #f)
(define menu-item-rules #f)
(define separator-menu-item-3166 #f)
(define menu-item-website #f)
(define separator-menu-item-3519 #f)
(define menu-item-about #f)
(define dialog-user #f)
(define vertical-panel-11846 #f)
(define horizontal-panel-12022 #f)
(define message-12047 #f)
(define text-field-user #f)
(define horizontal-panel-12244 #f)
(define message-12245 #f)
(define text-field-password #f)
(define horizontal-pane-16817 #f)
(define button-user-ok #f)
(define button-user-cancel #f)
(define frame-games #f)
(define horizontal-panel-3846 #f)
(define button-update-game-list #f)
(define cb-games-show-finished #f)
(define frame-rules #f)
(define text-field-rules #f)
(define dialog-new-game #f)
(define tab-panel-3694 #f)
(define tab-new-game #f)
(define msg-new-game-players #f)
(define choice-game-size #f)
(define radio-box-first-player #f)
(define tab-new-game-rules #f)
(define vp-new-game-rules #f)
(define msg-rules #f)
(define horizontal-pane-6515 #f)
(define button-new-game-ok #f)
(define button-new-game-cancel #f)
(define dialog-new-network-game #f)
(define list-box-opponent #f)
(define text-field-search-opponent #f)
(define horizontal-pane-5055 #f)
(define button-network-new-game-ok #f)
(define button-network-new-game-cancel #f)
(define dialog-preferences #f)
(define vertical-panel-9052 #f)
(define group-box-panel-3832 #f)
(define cb-prefs-auto-end-turn #f)
(define group-box-panel-3902 #f)
(define cb-prefs-auto-update #f)
(define cb-prefs-auto-update-notif #f)
(define tf-prefs-user #f)
(define tf-prefs-pwd #f)
(define group-box-panel-9121 #f)
(define tf-server-address #f)
(define tf-server-port #f)
(define tf-server-root-path #f)
(define tf-server-version #f)
(define horizontal-pane-15586 #f)
(define button-preferences-ok #f)
(define button-preferences-cancel #f)
(define vertical-panel-13649 #f)
(define horizontal-panel-11245 #f)
(define button-undo #f)
(define button-first #f)
(define button-previous-ply #f)
(define button-previous-move #f)
(define button-next-move #f)
(define button-next-ply #f)
(define button-last #f)
(define message-ply-number #f)
(define horizontal-panel-all #f)
(define vertical-panel-3624 #f)
(define button-update-game #f)
(define button-import #f)
(define button-end-turn #f)
(define button-resign #f)
(define vertical-panel-7573 #f)
(define vertical-panel-10845 #f)
(define message-player-two-name #f)
(define canvas-reserve-two #f)
(define panel-board #f)
(define canvas-reserve-one #f)
(define message-player-one-name #f)
(define dialog-create-user #f)
(define vertical-panel-41171 #f)
(define horizontal-panel-41172 #f)
(define message-41173 #f)
(define tf-new-user #f)
(define horizontal-panel-41175 #f)
(define message-41176 #f)
(define tf-new-pwd #f)
(define horizontal-panel-45101 #f)
(define message-45102 #f)
(define tf-new-email #f)
(define horizontal-pane-41178 #f)
(define button-create-user-ok #f)
(define button-create-user-cancel #f)
(require racket/runtime-path)
(define-runtime-path
 message-about-image-runtime-path
 "img/player-one-master.png")
(define-runtime-path button-undo-runtime-path "img/replay/undo-24.png")
(define-runtime-path
 button-first-runtime-path
 "img/replay/player_start-24.png")
(define-runtime-path
 button-previous-ply-runtime-path
 "img/replay/player_rew-24.png")
(define-runtime-path
 button-previous-move-runtime-path
 "img/replay/player_back-24.png")
(define-runtime-path
 button-next-move-runtime-path
 "img/replay/player_play-24.png")
(define-runtime-path
 button-next-ply-runtime-path
 "img/replay/player_fwd-24.png")
(define-runtime-path button-last-runtime-path "img/replay/player-end-24.png")
(define-runtime-path button-update-game-runtime-path "img/update-game-48.png")
(define-runtime-path button-import-runtime-path "img/import-48.png")
(define-runtime-path button-end-turn-runtime-path "img/end-turn-48.png")
(define-runtime-path button-resign-runtime-path "img/resign-48.png")
(define (frame-init
         #:main-frame-code-gen-class
         (main-frame-code-gen-class frame%)
         #:msg-about-towers-label
         (msg-about-towers-label (label-bitmap-proc (list "Towers" #f #f)))
         #:button-about-ok-callback
         (button-about-ok-callback (lambda (button control-event) (void)))
         #:menu-bar-demand-callback
         (menu-bar-demand-callback (lambda (m) (void)))
         #:menu-game-demand-callback
         (menu-game-demand-callback (lambda (m) (void)))
         #:menu-item-new-callback
         (menu-item-new-callback (lambda (item event) (void)))
         #:menu-item-new-demand-callback
         (menu-item-new-demand-callback (lambda (item) (void)))
         #:menu-item-open-callback
         (menu-item-open-callback (lambda (item event) (void)))
         #:menu-item-open-demand-callback
         (menu-item-open-demand-callback (lambda (item) (void)))
         #:menu-item-save-callback
         (menu-item-save-callback (lambda (item event) (void)))
         #:menu-item-save-demand-callback
         (menu-item-save-demand-callback (lambda (item) (void)))
         #:menu-item-show-rules-callback
         (menu-item-show-rules-callback (lambda (item event) (void)))
         #:menu-item-show-rules-demand-callback
         (menu-item-show-rules-demand-callback (lambda (item) (void)))
         #:menu-item-exit-callback
         (menu-item-exit-callback (lambda (item event) (void)))
         #:menu-item-exit-demand-callback
         (menu-item-exit-demand-callback (lambda (item) (void)))
         #:menu-network-demand-callback
         (menu-network-demand-callback (lambda (m) (void)))
         #:menu-item-user-callback
         (menu-item-user-callback (lambda (item event) (void)))
         #:menu-item-user-demand-callback
         (menu-item-user-demand-callback (lambda (item) (void)))
         #:menu-item-create-callback
         (menu-item-create-callback (lambda (item event) (void)))
         #:menu-item-create-demand-callback
         (menu-item-create-demand-callback (lambda (item) (void)))
         #:menu-item-games-callback
         (menu-item-games-callback (lambda (item event) (void)))
         #:menu-item-games-demand-callback
         (menu-item-games-demand-callback (lambda (item) (void)))
         #:menu-item-network-new-game-callback
         (menu-item-network-new-game-callback (lambda (item event) (void)))
         #:menu-item-network-new-game-demand-callback
         (menu-item-network-new-game-demand-callback (lambda (item) (void)))
         #:menu-item-stats-callback
         (menu-item-stats-callback (lambda (item event) (void)))
         #:menu-item-stats-demand-callback
         (menu-item-stats-demand-callback (lambda (item) (void)))
         #:menu-item-undo-callback
         (menu-item-undo-callback (lambda (item event) (void)))
         #:menu-item-undo-demand-callback
         (menu-item-undo-demand-callback (lambda (item) (void)))
         #:menu-item-preferences-callback
         (menu-item-preferences-callback (lambda (item event) (void)))
         #:menu-item-preferences-demand-callback
         (menu-item-preferences-demand-callback (lambda (item) (void)))
         #:menu-help-demand-callback
         (menu-help-demand-callback (lambda (m) (void)))
         #:menu-item-rules-callback
         (menu-item-rules-callback (lambda (item event) (void)))
         #:menu-item-rules-demand-callback
         (menu-item-rules-demand-callback (lambda (item) (void)))
         #:menu-item-website-callback
         (menu-item-website-callback (lambda (item event) (void)))
         #:menu-item-website-demand-callback
         (menu-item-website-demand-callback (lambda (item) (void)))
         #:menu-item-about-callback
         (menu-item-about-callback (lambda (item event) (void)))
         #:menu-item-about-demand-callback
         (menu-item-about-demand-callback (lambda (item) (void)))
         #:text-field-user-callback
         (text-field-user-callback (lambda (text-field control-event) (void)))
         #:text-field-password-callback
         (text-field-password-callback
          (lambda (text-field control-event) (void)))
         #:button-user-ok-callback
         (button-user-ok-callback (lambda (button control-event) (void)))
         #:button-user-cancel-callback
         (button-user-cancel-callback (lambda (button control-event) (void)))
         #:button-update-game-list-callback
         (button-update-game-list-callback
          (lambda (button control-event) (void)))
         #:cb-games-show-finished-callback
         (cb-games-show-finished-callback
          (lambda (button control-event) (void)))
         #:text-field-rules-callback
         (text-field-rules-callback (lambda (text-field control-event) (void)))
         #:choice-game-size-callback
         (choice-game-size-callback (lambda (choice control-event) (void)))
         #:radio-box-first-player-callback
         (radio-box-first-player-callback
          (lambda (radio-box control-event) (void)))
         #:button-new-game-ok-callback
         (button-new-game-ok-callback (lambda (button control-event) (void)))
         #:button-new-game-cancel-callback
         (button-new-game-cancel-callback
          (lambda (button control-event) (void)))
         #:list-box-opponent-callback
         (list-box-opponent-callback (lambda (list-box control-event) (void)))
         #:text-field-search-opponent-callback
         (text-field-search-opponent-callback
          (lambda (text-field control-event) (void)))
         #:button-network-new-game-ok-callback
         (button-network-new-game-ok-callback
          (lambda (button control-event) (void)))
         #:button-network-new-game-cancel-callback
         (button-network-new-game-cancel-callback
          (lambda (button control-event) (void)))
         #:cb-prefs-auto-end-turn-callback
         (cb-prefs-auto-end-turn-callback
          (lambda (button control-event) (void)))
         #:cb-prefs-auto-update-callback
         (cb-prefs-auto-update-callback (lambda (button control-event) (void)))
         #:cb-prefs-auto-update-notif-callback
         (cb-prefs-auto-update-notif-callback
          (lambda (button control-event) (void)))
         #:tf-prefs-user-callback
         (tf-prefs-user-callback (lambda (text-field control-event) (void)))
         #:tf-prefs-pwd-callback
         (tf-prefs-pwd-callback (lambda (text-field control-event) (void)))
         #:tf-server-address-callback
         (tf-server-address-callback
          (lambda (text-field control-event) (void)))
         #:tf-server-port-callback
         (tf-server-port-callback (lambda (text-field control-event) (void)))
         #:tf-server-root-path-callback
         (tf-server-root-path-callback
          (lambda (text-field control-event) (void)))
         #:tf-server-version-callback
         (tf-server-version-callback
          (lambda (text-field control-event) (void)))
         #:button-preferences-ok-callback
         (button-preferences-ok-callback
          (lambda (button control-event) (void)))
         #:button-preferences-cancel-callback
         (button-preferences-cancel-callback
          (lambda (button control-event) (void)))
         #:button-undo-callback
         (button-undo-callback (lambda (button control-event) (void)))
         #:button-first-callback
         (button-first-callback (lambda (button control-event) (void)))
         #:button-previous-ply-callback
         (button-previous-ply-callback (lambda (button control-event) (void)))
         #:button-previous-move-callback
         (button-previous-move-callback (lambda (button control-event) (void)))
         #:button-next-move-callback
         (button-next-move-callback (lambda (button control-event) (void)))
         #:button-next-ply-callback
         (button-next-ply-callback (lambda (button control-event) (void)))
         #:button-last-callback
         (button-last-callback (lambda (button control-event) (void)))
         #:button-update-game-callback
         (button-update-game-callback (lambda (button control-event) (void)))
         #:button-import-callback
         (button-import-callback (lambda (button control-event) (void)))
         #:button-end-turn-callback
         (button-end-turn-callback (lambda (button control-event) (void)))
         #:button-resign-callback
         (button-resign-callback (lambda (button control-event) (void)))
         #:canvas-reserve-two-paint-callback
         (canvas-reserve-two-paint-callback (λ (canvas dc) (void)))
         #:canvas-reserve-one-paint-callback
         (canvas-reserve-one-paint-callback (λ (canvas dc) (void)))
         #:tf-new-user-callback
         (tf-new-user-callback (lambda (text-field control-event) (void)))
         #:tf-new-pwd-callback
         (tf-new-pwd-callback (lambda (text-field control-event) (void)))
         #:tf-new-email-callback
         (tf-new-email-callback (lambda (text-field control-event) (void)))
         #:button-create-user-ok-callback
         (button-create-user-ok-callback
          (lambda (button control-event) (void)))
         #:button-create-user-cancel-callback
         (button-create-user-cancel-callback
          (lambda (button control-event) (void))))
  (set! main-frame
    (new
     main-frame-code-gen-class
     (parent frame)
     (label "Towers")
     (width #f)
     (height #f)
     (x 200)
     (y 0)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 30)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! dialog-about
    (new
     dialog%
     (parent main-frame)
     (label "About")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 450)
     (min-height 30)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! horizontal-pane-3542
    (new
     horizontal-pane%
     (parent dialog-about)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! message-about-image
    (new
     message%
     (parent horizontal-pane-3542)
     (label
      (label-bitmap-proc (list "<image>" #t message-about-image-runtime-path)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! msg-about-towers
    (new
     message%
     (parent horizontal-pane-3542)
     (label msg-about-towers-label)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-22281
    (new
     message%
     (parent dialog-about)
     (label (label-bitmap-proc (list "www.towers-game.net" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-3520
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list "(c) Laurent Orseau 2010-2013, GPLv3 license" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! pane-24649
    (new
     pane%
     (parent dialog-about)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 40)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! message-22222
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list "Written in Racket: www.racket-lang.org" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-24602
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list
        "GUI developed with MrEd Designer: https://github.com/Metaxal/MrEd-Designer"
        #f
        #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-3865
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list "Graphics created with Gimp: www.gimp.org" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-4045
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list "Icons based on Crystal Clear: www.everaldo.com/crystal/" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! pane-29300
    (new
     pane%
     (parent dialog-about)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 40)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! message-29351
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list
        "Many thanks to Lom, Claire, Nannig, Elucterio, Antoine, Fabien,"
        #f
        #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! message-29464
    (new
     message%
     (parent dialog-about)
     (label
      (label-bitmap-proc
       (list
        "the Racket community and many other people for their help and their support."
        #f
        #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! button-about-ok
    (new
     button%
     (parent dialog-about)
     (label (label-bitmap-proc (list "Ok" #f #f)))
     (callback button-about-ok-callback)
     (style '(border))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 10)
     (horiz-margin 2)
     (min-width 80)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! menu-bar
    (new
     menu-bar%
     (parent main-frame)
     (demand-callback menu-bar-demand-callback)))
  (set! menu-game
    (new
     menu%
     (parent menu-bar)
     (label "&Game")
     (help-string "Game")
     (demand-callback menu-game-demand-callback)))
  (set! menu-item-new
    (new
     menu-item%
     (parent menu-game)
     (label "&New Local Game")
     (callback menu-item-new-callback)
     (shortcut #\N)
     (help-string "Create a new game")
     (demand-callback menu-item-new-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-item-open
    (new
     menu-item%
     (parent menu-game)
     (label "&Open Game")
     (callback menu-item-open-callback)
     (shortcut #\O)
     (help-string "Item")
     (demand-callback menu-item-open-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-item-save
    (new
     menu-item%
     (parent menu-game)
     (label "&Save Game")
     (callback menu-item-save-callback)
     (shortcut #\S)
     (help-string "Item")
     (demand-callback menu-item-save-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! separator-menu-item-9516 (new separator-menu-item% (parent menu-game)))
  (set! menu-item-show-rules
    (new
     menu-item%
     (parent menu-game)
     (label "&Show/hide specific rules")
     (callback menu-item-show-rules-callback)
     (shortcut #\R)
     (help-string "Show the specific rules of the current game")
     (demand-callback menu-item-show-rules-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! separator-menu-item-3191 (new separator-menu-item% (parent menu-game)))
  (set! menu-item-exit
    (new
     menu-item%
     (parent menu-game)
     (label "&Exit")
     (callback menu-item-exit-callback)
     (shortcut #f)
     (help-string "Exit Application")
     (demand-callback menu-item-exit-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-network
    (new
     menu%
     (parent menu-bar)
     (label "&Network")
     (help-string "Network")
     (demand-callback menu-network-demand-callback)))
  (set! menu-item-user
    (new
     menu-item%
     (parent menu-network)
     (label "&Login")
     (callback menu-item-user-callback)
     (shortcut #\L)
     (help-string "Login")
     (demand-callback menu-item-user-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-item-create
    (new
     menu-item%
     (parent menu-network)
     (label "&Create Network Player")
     (callback menu-item-create-callback)
     (shortcut #f)
     (help-string "Item")
     (demand-callback menu-item-create-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-item-games
    (new
     menu-item%
     (parent menu-network)
     (label "&Show/Update Games")
     (callback menu-item-games-callback)
     (shortcut #\G)
     (help-string "Show network games")
     (demand-callback menu-item-games-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-item-network-new-game
    (new
     menu-item%
     (parent menu-network)
     (label "&New Network Game")
     (callback menu-item-network-new-game-callback)
     (shortcut #\N)
     (help-string "New network game")
     (demand-callback menu-item-network-new-game-demand-callback)
     (shortcut-prefix '(ctl shift))))
  (set! separator-menu-item-3877
    (new separator-menu-item% (parent menu-network)))
  (set! menu-item-stats
    (new
     menu-item%
     (parent menu-network)
     (label "&Statistics (online)")
     (callback menu-item-stats-callback)
     (shortcut #f)
     (help-string "Item")
     (demand-callback menu-item-stats-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-edit
    (new
     menu%
     (parent menu-bar)
     (label "&Edit")
     (help-string "Edit")
     (demand-callback (lambda (m) (void)))))
  (set! menu-item-undo
    (new
     menu-item%
     (parent menu-edit)
     (label "&Undo game move")
     (callback menu-item-undo-callback)
     (shortcut #\Z)
     (help-string "Item")
     (demand-callback menu-item-undo-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! separator-menu-item-3841 (new separator-menu-item% (parent menu-edit)))
  (set! menu-item-preferences
    (new
     menu-item%
     (parent menu-edit)
     (label "&Preferences")
     (callback menu-item-preferences-callback)
     (shortcut #f)
     (help-string "Item")
     (demand-callback menu-item-preferences-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! menu-help
    (new
     menu%
     (parent menu-bar)
     (label "&Help")
     (help-string "Help")
     (demand-callback menu-help-demand-callback)))
  (set! menu-item-rules
    (new
     menu-item%
     (parent menu-help)
     (label "&Game Rules and Help")
     (callback menu-item-rules-callback)
     (shortcut 'f1)
     (help-string "Item")
     (demand-callback menu-item-rules-demand-callback)
     (shortcut-prefix '())))
  (set! separator-menu-item-3166 (new separator-menu-item% (parent menu-help)))
  (set! menu-item-website
    (new
     menu-item%
     (parent menu-help)
     (label "&Towers Web site")
     (callback menu-item-website-callback)
     (shortcut #f)
     (help-string "Go to website")
     (demand-callback menu-item-website-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! separator-menu-item-3519 (new separator-menu-item% (parent menu-help)))
  (set! menu-item-about
    (new
     menu-item%
     (parent menu-help)
     (label "&About")
     (callback menu-item-about-callback)
     (shortcut #f)
     (help-string "About")
     (demand-callback menu-item-about-demand-callback)
     (shortcut-prefix '(ctl))))
  (set! dialog-user
    (new
     dialog%
     (parent main-frame)
     (label "Log in to server")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 30)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! vertical-panel-11846
    (new
     vertical-panel%
     (parent dialog-user)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! horizontal-panel-12022
    (new
     horizontal-panel%
     (parent vertical-panel-11846)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-12047
    (new
     message%
     (parent horizontal-panel-12022)
     (label (label-bitmap-proc (list "Login:" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! text-field-user
    (new
     text-field%
     (parent horizontal-panel-12022)
     (label "")
     (callback text-field-user-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 200)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! horizontal-panel-12244
    (new
     horizontal-panel%
     (parent vertical-panel-11846)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-12245
    (new
     message%
     (parent horizontal-panel-12244)
     (label (label-bitmap-proc (list "Password:" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! text-field-password
    (new
     text-field%
     (parent horizontal-panel-12244)
     (label "")
     (callback text-field-password-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '(password))))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 200)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! horizontal-pane-16817
    (new
     horizontal-pane%
     (parent dialog-user)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! button-user-ok
    (new
     button%
     (parent horizontal-pane-16817)
     (label (label-bitmap-proc (list "Ok" #f #f)))
     (callback button-user-ok-callback)
     (style '(border))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-user-cancel
    (new
     button%
     (parent horizontal-pane-16817)
     (label (label-bitmap-proc (list "Cancel" #f #f)))
     (callback button-user-cancel-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! frame-games
    (new
     frame%
     (parent main-frame)
     (label "Games")
     (width 560)
     (height 200)
     (x 800)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 50)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! horizontal-panel-3846
    (new
     horizontal-panel%
     (parent frame-games)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! button-update-game-list
    (new
     button%
     (parent horizontal-panel-3846)
     (label (label-bitmap-proc (list "Update list" #f #f)))
     (callback button-update-game-list-callback)
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! cb-games-show-finished
    (new
     check-box%
     (parent horizontal-panel-3846)
     (label (label-bitmap-proc (list "Show finished games" #f #f)))
     (callback cb-games-show-finished-callback)
     (style '())
     (value #f)
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! frame-rules
    (new
     frame%
     (parent main-frame)
     (label "Specific rules")
     (width #f)
     (height #f)
     (x 800)
     (y 400)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 400)
     (min-height 200)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! text-field-rules
    (new
     text-field%
     (parent frame-rules)
     (label "")
     (callback text-field-rules-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'multiple 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #f)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! dialog-new-game
    (new
     dialog%
     (parent main-frame)
     (label "New Game")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 30)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! tab-panel-3694
    (new
     (class tab-panel%
       (super-new)
       (define single-panel (new panel:single% (parent this)))
       (define/public (get-single-panel) single-panel)
       (define child-panels '())
       (define/public
        (add-child-panel p label)
        (set! child-panels (append child-panels (list p)))
        (send this append label))
       (define/public
        (active-child n)
        (send single-panel active-child (list-ref child-panels n))))
     (parent dialog-new-game)
     (choices (list))
     (callback (λ (tp e) (send tp active-child (send tp get-selection))))
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! tab-new-game
    (new
     (class vertical-panel%
       (init parent)
       (init-field label)
       (super-new (parent (send parent get-single-panel)))
       (send parent add-child-panel this label))
     (parent tab-panel-3694)
     (label "Game")
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! msg-new-game-players
    (new
     message%
     (parent tab-new-game)
     (label (label-bitmap-proc (list "Player one VS Player two" #f #f)))
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #t)))
  (set! choice-game-size
    (new
     choice%
     (parent tab-new-game)
     (label "Game size:")
     (choices (list "5x5" "6x6" "7x7" "8x8" "9x9" "10x10"))
     (callback choice-game-size-callback)
     (style
      ((λ (l) (list* (first l) (second l))) (list 'horizontal-label '())))
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (selection 0)
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! radio-box-first-player
    (new
     radio-box%
     (parent tab-new-game)
     (label "Who plays first:")
     (choices (list "Me" "Opponent"))
     (callback radio-box-first-player-callback)
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'vertical 'horizontal-label '())))
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (selection 0)
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! tab-new-game-rules
    (new
     (class vertical-panel%
       (init parent)
       (init-field label)
       (super-new (parent (send parent get-single-panel)))
       (send parent add-child-panel this label))
     (parent tab-panel-3694)
     (label "Specific rules")
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! vp-new-game-rules
    (new
     vertical-panel%
     (parent tab-new-game-rules)
     (style '(border))
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! msg-rules
    (new
     message%
     (parent vp-new-game-rules)
     (label (label-bitmap-proc (list "Specific rules (non official):" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! horizontal-pane-6515
    (new
     horizontal-pane%
     (parent tab-panel-3694)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! button-new-game-ok
    (new
     button%
     (parent horizontal-pane-6515)
     (label (label-bitmap-proc (list "Ok" #f #f)))
     (callback button-new-game-ok-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-new-game-cancel
    (new
     button%
     (parent horizontal-pane-6515)
     (label (label-bitmap-proc (list "Cancel" #f #f)))
     (callback button-new-game-cancel-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! dialog-new-network-game
    (new
     dialog%
     (parent main-frame)
     (label "Opponent")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 150)
     (min-height 200)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! list-box-opponent
    (new
     list-box%
     (parent dialog-new-network-game)
     (label "Select opponent:")
     (choices (list "First"))
     (callback list-box-opponent-callback)
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'vertical-label '())))
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (selection 0)
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! text-field-search-opponent
    (new
     text-field%
     (parent dialog-new-network-game)
     (label "Search:")
     (callback text-field-search-opponent-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! horizontal-pane-5055
    (new
     horizontal-pane%
     (parent dialog-new-network-game)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! button-network-new-game-ok
    (new
     button%
     (parent horizontal-pane-5055)
     (label (label-bitmap-proc (list "Next" #f #f)))
     (callback button-network-new-game-ok-callback)
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-network-new-game-cancel
    (new
     button%
     (parent horizontal-pane-5055)
     (label (label-bitmap-proc (list "Cancel" #f #f)))
     (callback button-network-new-game-cancel-callback)
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! dialog-preferences
    (new
     dialog%
     (parent main-frame)
     (label "Preferences")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 30)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! vertical-panel-9052
    (new
     vertical-panel%
     (parent dialog-preferences)
     (style '(border))
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! group-box-panel-3832
    (new
     group-box-panel%
     (parent vertical-panel-9052)
     (label "Game")
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! cb-prefs-auto-end-turn
    (new
     check-box%
     (parent group-box-panel-3832)
     (label (label-bitmap-proc (list "Automatically end turn" #f #f)))
     (callback cb-prefs-auto-end-turn-callback)
     (style '())
     (value #t)
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! group-box-panel-3902
    (new
     group-box-panel%
     (parent vertical-panel-9052)
     (label "Network")
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! cb-prefs-auto-update
    (new
     check-box%
     (parent group-box-panel-3902)
     (label
      (label-bitmap-proc (list "Automatically update network games" #f #f)))
     (callback cb-prefs-auto-update-callback)
     (style '())
     (value #t)
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! cb-prefs-auto-update-notif
    (new
     check-box%
     (parent group-box-panel-3902)
     (label (label-bitmap-proc (list "Notify when game is updated" #f #f)))
     (callback cb-prefs-auto-update-notif-callback)
     (style '())
     (value #t)
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! tf-prefs-user
    (new
     text-field%
     (parent group-box-panel-3902)
     (label "User:")
     (callback tf-prefs-user-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! tf-prefs-pwd
    (new
     text-field%
     (parent group-box-panel-3902)
     (label "Password:")
     (callback tf-prefs-pwd-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '(password))))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! group-box-panel-9121
    (new
     group-box-panel%
     (parent vertical-panel-9052)
     (label "Server")
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! tf-server-address
    (new
     text-field%
     (parent group-box-panel-9121)
     (label "Address:")
     (callback tf-server-address-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! tf-server-port
    (new
     text-field%
     (parent group-box-panel-9121)
     (label "Port:")
     (callback tf-server-port-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! tf-server-root-path
    (new
     text-field%
     (parent group-box-panel-9121)
     (label "Root path:")
     (callback tf-server-root-path-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! tf-server-version
    (new
     text-field%
     (parent group-box-panel-9121)
     (label "Version:")
     (callback tf-server-version-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! horizontal-pane-15586
    (new
     horizontal-pane%
     (parent dialog-preferences)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! button-preferences-ok
    (new
     button%
     (parent horizontal-pane-15586)
     (label (label-bitmap-proc (list "Ok" #f #f)))
     (callback button-preferences-ok-callback)
     (style '(border))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-preferences-cancel
    (new
     button%
     (parent horizontal-pane-15586)
     (label (label-bitmap-proc (list "Cancel" #f #f)))
     (callback button-preferences-cancel-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! vertical-panel-13649
    (new
     vertical-panel%
     (parent main-frame)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! horizontal-panel-11245
    (new
     horizontal-panel%
     (parent vertical-panel-13649)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! button-undo
    (new
     button%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list "Undo" #t button-undo-runtime-path)))
     (callback button-undo-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 8)
     (min-width 32)
     (min-height 32)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-first
    (new
     button%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list "|<" #t button-first-runtime-path)))
     (callback button-first-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-previous-ply
    (new
     button%
     (parent horizontal-panel-11245)
     (label
      (label-bitmap-proc (list "<<" #t button-previous-ply-runtime-path)))
     (callback button-previous-ply-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-previous-move
    (new
     button%
     (parent horizontal-panel-11245)
     (label
      (label-bitmap-proc (list "<" #t button-previous-move-runtime-path)))
     (callback button-previous-move-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-next-move
    (new
     button%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list ">" #t button-next-move-runtime-path)))
     (callback button-next-move-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-next-ply
    (new
     button%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list ">>" #t button-next-ply-runtime-path)))
     (callback button-next-ply-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-last
    (new
     button%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list ">|" #t button-last-runtime-path)))
     (callback button-last-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 30)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! message-ply-number
    (new
     message%
     (parent horizontal-panel-11245)
     (label (label-bitmap-proc (list "0/0" #f #f)))
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #t)))
  (set! horizontal-panel-all
    (new
     horizontal-panel%
     (parent vertical-panel-13649)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'left 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! vertical-panel-3624
    (new
     vertical-panel%
     (parent horizontal-panel-all)
     (style '(border))
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-update-game
    (new
     button%
     (parent vertical-panel-3624)
     (label
      (label-bitmap-proc
       (list "Update game" #t button-update-game-runtime-path)))
     (callback button-update-game-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 48)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-import
    (new
     button%
     (parent vertical-panel-3624)
     (label (label-bitmap-proc (list "Import" #t button-import-runtime-path)))
     (callback button-import-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 48)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-end-turn
    (new
     button%
     (parent vertical-panel-3624)
     (label
      (label-bitmap-proc (list "End Turn" #t button-end-turn-runtime-path)))
     (callback button-end-turn-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 48)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-resign
    (new
     button%
     (parent vertical-panel-3624)
     (label (label-bitmap-proc (list "Resign" #t button-resign-runtime-path)))
     (callback button-resign-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 48)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! vertical-panel-7573
    (new
     vertical-panel%
     (parent horizontal-panel-all)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! vertical-panel-10845
    (new
     vertical-panel%
     (parent vertical-panel-7573)
     (style '(border))
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-player-two-name
    (new
     message%
     (parent vertical-panel-10845)
     (label (label-bitmap-proc (list "Player Two" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #t)))
  (set! canvas-reserve-two
    (new
     canvas%
     (parent vertical-panel-10845)
     (style '(border))
     (paint-callback canvas-reserve-two-paint-callback)
     (label "Canvas")
     (gl-config #f)
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (min-width 48)
     (min-height 48)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! panel-board
    (new
     panel%
     (parent vertical-panel-10845)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! canvas-reserve-one
    (new
     canvas%
     (parent vertical-panel-10845)
     (style '(border))
     (paint-callback canvas-reserve-one-paint-callback)
     (label "Canvas")
     (gl-config #f)
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (min-width 48)
     (min-height 48)
     (stretchable-width #t)
     (stretchable-height #f)))
  (set! message-player-one-name
    (new
     message%
     (parent vertical-panel-10845)
     (label (label-bitmap-proc (list "Player One" #f #f)))
     (style '())
     (font (list->font (list 8 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #t)))
  (set! dialog-create-user
    (new
     dialog%
     (parent main-frame)
     (label "Create new user")
     (width #f)
     (height #f)
     (x #f)
     (y #f)
     (style '())
     (enabled #t)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'top))
     (min-width 70)
     (min-height 30)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! vertical-panel-41171
    (new
     vertical-panel%
     (parent dialog-create-user)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'top))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! horizontal-panel-41172
    (new
     horizontal-panel%
     (parent vertical-panel-41171)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-41173
    (new
     message%
     (parent horizontal-panel-41172)
     (label (label-bitmap-proc (list "Login:" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! tf-new-user
    (new
     text-field%
     (parent horizontal-panel-41172)
     (label "")
     (callback tf-new-user-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 200)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! horizontal-panel-41175
    (new
     horizontal-panel%
     (parent vertical-panel-41171)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-41176
    (new
     message%
     (parent horizontal-panel-41175)
     (label (label-bitmap-proc (list "Password:" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! tf-new-pwd
    (new
     text-field%
     (parent horizontal-panel-41175)
     (label "")
     (callback tf-new-pwd-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '(password))))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 200)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! horizontal-panel-45101
    (new
     horizontal-panel%
     (parent vertical-panel-41171)
     (style '())
     (enabled #t)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'right 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! message-45102
    (new
     message%
     (parent horizontal-panel-45101)
     (label (label-bitmap-proc (list "Email:" #f #f)))
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 0)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)
     (auto-resize #f)))
  (set! tf-new-email
    (new
     text-field%
     (parent horizontal-panel-45101)
     (label "")
     (callback tf-new-email-callback)
     (init-value "")
     (style
      ((λ (l) (list* (first l) (second l) (third l)))
       (list 'single 'horizontal-label '())))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 200)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! horizontal-pane-41178
    (new
     horizontal-pane%
     (parent dialog-create-user)
     (vert-margin 0)
     (horiz-margin 0)
     (border 0)
     (spacing 0)
     (alignment (list 'center 'center))
     (min-width 0)
     (min-height 0)
     (stretchable-width #t)
     (stretchable-height #t)))
  (set! button-create-user-ok
    (new
     button%
     (parent horizontal-pane-41178)
     (label (label-bitmap-proc (list "Create user" #f #f)))
     (callback button-create-user-ok-callback)
     (style '(border))
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f)))
  (set! button-create-user-cancel
    (new
     button%
     (parent horizontal-pane-41178)
     (label (label-bitmap-proc (list "Cancel" #f #f)))
     (callback button-create-user-cancel-callback)
     (style '())
     (font (list->font (list 8 #f 'default 'normal 'normal #f 'default #f)))
     (enabled #t)
     (vert-margin 2)
     (horiz-margin 2)
     (min-width 60)
     (min-height 0)
     (stretchable-width #f)
     (stretchable-height #f))))
