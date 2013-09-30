#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)


;;; TODO: Double salt! Salt on client and salt on server
;;; Otherwise the password are as good as not salted...

(require (prefix-in db: "db.rkt")
         ;towers-lib/preferences
         towers-lib/base
         (only-in towers-lib/connection make-salt)
         towers-lib/game
         towers-lib/player
         bazaar/list
         bazaar/string
         bazaar/net/smtp
         web-server/servlet
         web-server/servlet-env
         web-server/page
         racket/format
         racket/list
         racket/dict
         racket/class
         racket/string
         racket/port)

(provide start-server
         run-server
         create-user/cmd-line
         create-towers-database
         create-preferences
         towers-server-logger)

(define-logger towers-server)

(define smtp-send #f)

;; WARNING: http://docs.racket-lang.org/db/using-db.html?q=mysql-connect#%28part._intro-servlets%29

(define (create-user user pwd salt email)
  (log-info "Creating user: ~a" user)
  ; TODO: send a confirmation email with a token
  ; (plus ask to enter a word on the webpage?)
  (define res
    (if (< (string-length user) 2)
        (fail "User name must be at least 2 letters long.")
        (db:create-user user pwd salt email)))
  (when smtp-send
    (smtp-send (send prefs get 'email-to)
               "[Towers] create-user"
               (format "New user: ~a" user)))
  res)

(define (update-game user game-id ply)
  (define lg (first (db:get-game user game-id)))
  (define g (list-game->game lg "ServerTest" "ServerTest")) ; raises error if incorrect game

  (send g replay-game)
  (log-debug "Plies1: ~a" (send g get-plies))
  (when (send g play-ply ply) ; if illegal move, does nothing
    (log-debug "Plies2: ~a" (send g get-plies))
    (unless (send g new-ply?)
      (send g end-player-turn)) ;force end the current player's turn, if not already a new ply
    (log-debug "Plies3: ~a" (send g get-plies))
    (define winner (send g get-winner))
    (db:update-game user game-id (send g game->list)
                    (send g get-current-name) (if winner (send winner get-name) "")))

  ;todo:
  ; send email to next player
  )

(define (create-game user user1 user2 size game)
  (define id (db:create-game user user1 user2 size game user1))
  (when smtp-send
    (smtp-send (send prefs get 'email-to)
               "[Towers] create-game"
               (format "~a created a new game #~a: ~a vs ~a" user id user1 user2)))
  id)

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
                 (create-user user pwd (get-value 'salt) (get-value 'email))]
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
                        (create-game user (get-value 'user1) (get-value 'user2)
                                     (get-value 'size) (get-value 'game))]
                       [("getgame")
                        (db:get-game user (get-value 'gameid))]
                       [("acceptgame")
                        (db:accept-game user (get-value 'gameid))]
                       [("rejectgame")
                        (db:reject-game user (get-value 'gameid))]
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
                       [("listaskgames")
                        (db:get-ask-game-list user)]
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
  (when database (send prefs set 'database database #:save? #f))
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

(define (run-server)
  (db:set-auto-connection)
  (define smtp-server (send prefs get 'smtp-server #f))
  (when smtp-server
    (set! smtp-send
          (make-smtp-send
           smtp-server
           (send prefs get 'email-from)
           #:auth-user (send prefs get 'smtp-user)
           #:auth-passwd (send prefs get 'smtp-password)
           #:port-no (send prefs get 'smtp-port))))
  (start-server))

(define (create-user/cmd-line user pwd email)
  (log-info "Creating user ~a <~a>" user email)
  (db:set-auto-connection)
  (db:create-user user pwd (make-salt) email))

(define (create-towers-database)
  (log-info "Creating database: ~a\n" (send prefs get 'database))
  (db:set-connection (send prefs get 'mysql-user)
                     (send prefs get 'mysql-password)
                     #f)
  (db:create-database (send prefs get 'database))
  (db:select-database (send prefs get 'database))
  (db:create-towers-tables))

(define (create-preferences)
  (define keys
    `((mysql-user "root")
      (mysql-password "")
      (database "towers")
      (server-address "localhost")
      (server-root-path "towers")
      (server-version "2.0")
      (server-port 8080 #f ,number->string ,string->number)
      (smtp-server #f "(Enter \"no\" to disable emails)" 
                   ,(λ(s)(string-or-false->string s "no"))
                   ,(λ(s)(string->string-or-false s "no")))
      (smtp-user "")
      (smtp-password "")
      (smtp-port 25 #f ,number->string ,string->number)
      (email-from "")
      (email-to "")
      ))

  ; This could well go into bazaar/preferences.rkt
  (define (ask key default [msg #f] [->str values] [str-> values])
    (define v0 (send prefs get key default))
    (printf "~a [~a]~a: " key (->str v0) (or msg ""))
    (define str (read-line))
    (send prefs set key (if (equal? str "")
                            v0
                            (str-> str))))

  (printf "Saving preferences to ~a\n" (send prefs get-file))

  (for ([v keys])
    (apply ask v))

  (send prefs save)
  )
