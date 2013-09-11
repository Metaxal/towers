#!/usr/bin/env racket
#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require (prefix-in db: "db.rkt")
         ;towers-lib/preferences
         towers-lib/base
         towers-lib/game
         towers-lib/player
         bazaar/list
         web-server/servlet
         web-server/servlet-env
         web-server/page
         racket/format
         racket/list
         racket/class
         racket/string
         racket/port)

(provide start-server towers-server-logger)

(define-logger towers-server)

;; WARNING: http://docs.racket-lang.org/db/using-db.html?q=mysql-connect#%28part._intro-servlets%29

(define (update-game user game-id ply)
  (define lg (db:get-game user game-id))
  (define g (list-game->game lg "ServerTest" "ServerTest")) ; raises error if incorrect game

  (send g replay-game)
  (log-debug "Plies1: ~a" (send g get-plies))
  (when (send g play-ply ply) ; if illegal move, does nothing
    (log-debug "Plies2: ~a" (send g get-plies))
    (unless (send g new-ply?)
      (send g play-move 'end)) ;force end the current player's turn, if not already a new ply
    (log-debug "Plies3: ~a" (send g get-plies))
    (define winner (send g get-winner))
    (db:update-game user game-id (send g game->list)
                    (send g get-current-name) (if winner (send winner get-name) "")))
  
  ;todo:
  ; send email to next player
  )

(define (fail . msgs)
    (list
     'Error
     (apply string-append (map ~a msgs))
     ))

(define (start req)
  (define response #f)
  (with-handlers ([values (λ(e)(set! response (fail (exn-message e))))])
    (define (get-value sym [default #f])
      (or (get-binding sym req) default))
    (define date     (get-value 'date 0))
    (define user     (get-value 'user))
    (define pwd      (get-value 'password))
    (define version  (get-value 'version))
    (define action   (get-value 'action))
    (log-debug 
     (string-append
      "Request params: "
      (string-join (map ~v (list date user pwd version action)))))
    
    (set! response 
          (cond [(not user)
                 (fail "Username must be provided")]
                [(equal? action "newuser")
                 (log-info "Creating user: ~a" user)
                 ; TODO: send a confirmation email with a token
                 ; (plus ask to enter a word on the webpage?)
                 (if (< (string-length user) 2)
                     (fail "User name must be at least 2 letters long.")
                     (db:create-user user pwd (get-value 'salt) (get-value 'email)))]
                [(equal? action "getsalt")
                 (or (db:get-salt user)
                     (fail "Could not retrieve salt for user " user))]
                [(and action pwd)
                 (if (not (db:verify-user user pwd))
                     (fail "Could not verify user identity for user " user)
                     (case action
                       [("getplayers")
                        (db:get-players)]
                       [("newgame")
                        (define user1 (get-value 'user1))
                        (db:create-game user user1 (get-value 'user2)
                                        (get-value 'size) (get-value 'game) user1)]
                       [("getgame")
                        (db:get-game user (get-value 'gameid))]
                       [("updategame")
                        (define game-id (get-value 'gameid))
                        (define ply-str (get-value 'ply))
                        (define ply (let ([ply (port->list read (open-input-string ply-str))])
                                      (and (not (empty? ply))
                                           (first ply))))
                        (log-info "Updating game ~a" game-id)
                        (update-game user game-id ply)]
                       [("listgames")
                        (db:get-game-list user)]
                       [("listcurrentgames")
                        (db:get-current-game-list user)]
                       [("checkauth") #t]
                       [else (fail "bad request (auth Ok)")]))]
                [else (fail "bad request")]
                )))
  (log-debug "Response:\n ~a" response)
  
  (response/xexpr (~v response)))
  
;; database : (or/c #f string/c). Useful only if db-auto-connect is #t
(define (start-server #:database [database #f])
  (when database   (send prefs set 'database database #:save? #f))
  (serve/servlet start
                 ;#:command-line? #t
                 #:launch-browser? #f
                 ;#:connection-close? #t ; ?
                 #:listen-ip #f ; listen to every-one
                 #:port (server-port)
                 #:servlet-path (string-append "/" (server-root-path) 
                                               "/" (server-version))
                 )
  (db:close-connection))

;; test with:
;; curl 'http://localhost:8000/do?a=b'

(module+ main
  (require racket/cmdline)
  (parameterize ([current-logger towers-server-logger])
    (command-line 
     #:once-any
     [("-p" "--preferences") file
                             "Sets the preference file"
                             (pref-file file)]
     [("--create-db") "Creates Towers database with empty tables if it does not exist"
                      (load-preferences)
                      (db:set-connection (send prefs get 'mysql-user)
                                         (send prefs get 'mysql-password)
                                         #f)
                      (db:create-database (send prefs get 'database))
                      (db:select-database (send prefs get 'database))
                      (db:create-towers-tables)
                      (exit)]
     #:args ()
     (load-preferences)
     (db:set-auto-connection)
     (start-server))))
