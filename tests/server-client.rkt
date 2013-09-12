#lang racket
(require (prefix-in db: towers-server/db)
         towers-server/server
         towers-lib/base
         towers-lib/connection
         towers-lib/game
         (only-in towers-server/db 
                  set-auto-connection 
                  get-connection
                  )
         bazaar/rackunit)

(current-logger no-logger)
(define tll-rc (make-log-receiver towers-lib-logger 'debug))
(define tls-rc (make-log-receiver towers-server-logger 'debug))
(loop-receive tll-rc #;tls-rc)

(load-preferences "prefs-test.rktd")
;(send prefs set 'database #f #:save? #f) ; the database may not exist yet.
;(send prefs set 'server-port "8081")
(db:set-connection
 (send prefs get 'mysql-user) (send prefs get 'mysql-password) #f)

(db:create-database (send prefs get 'database) #:exists 'drop)
(db:select-database (send prefs get 'database))
(db:create-towers-tables)

;; Reset the connection, with the newly created database.
;; This is important because the server uses a connection pool,
;; with the default arguments for database, which (select-database may not always affect).
(db:set-auto-connection 
 #:notice-handler (λ(a b)(list a b))#;'error)

(log-debug "Starting server.")
; Do not init server, because we want to use the bd settings defined above
(parameterize ([current-logger towers-server-logger])
  (thread start-server))
(sleep 3)
(log-debug "Server started (hopefully).")

(check-fail (create-user "" "" ""))

(check-not-fail (create-user "plip" "plop" "plip@plop.com"))
(check-not-fail (set-user-password "plip" "plop"))
(check-authentication)
(check-true (check-authentication))
; create user plop with pwd plip
(check-not-fail (create-user "plap" "plup" "plap@plup.com"))
; duplicate identifier test
(check-fail (create-user "plap" "plup" "plap@plup.com"))
(check-not-fail (set-user-password "plap" "plup"))
(check-true (check-authentication))
; Do not move these tests, they must be first
(let ()
  (log-debug "\nCreating game")
  (define g (new network-game% [nb-cells 5] [player1-class "Human"] [player2-class "Human"]
                 [player1-name "plip"] [player2-name "plap"]))
  (define net-id (new-game g))
  (check-pred number? net-id)
  (check-pred number? (new-game g))
  (let ([lg (get-game-list)])
    (check-equal? (length lg) 2)
    (check-pred (listof vector?) lg))
  ; Change user, verify that it sees the games too
  (set-user-password "plip" "plop")
  (check-equal? (length (get-game-list)) 2)
  
  (log-debug "\n\nGet game g1")
  (define g1 (get-game net-id))
  (check-pred (is-a?/c game<%>) g1)
  (debug-game g1)
  
  (send g1 play-move '(move 0 3 0 2 #f)) ; may trigger an update
  (send g1 play-move 'end)
  (log-debug "Plies: ~a" (send g1 get-plies))
  (debug-game g1)
  
  (log-debug "Get game g2")
  (define g2 (get-game net-id))
  (debug-game g2)
  
  ;; Illegal because not logged in as plap!
  (send g2 play-move '(move 0 1 0 2 #f))
  ;(send g2 play-move 'end) ; warning ! Will switch the players!
  (debug-game g2)
  
  (set-user-password "plap" "plup")
  (check-true (check-authentication))
  (log-debug "Current-name: ~a" (send g2 get-current-name))
  (send g2 play-move '(move 0 1 0 2 #f)) ; Does not work?!
  (send g2 play-move 'end)
  (debug-game g2)
  
  (log-debug "Get game g3")
  (set-user-password "plip" "plop")
  (define g3 (get-game net-id))
  (send g3 play-move '(move 3 4 2 4 #f)) ; Does not work?!
  (send g3 play-move 'end)
  (debug-game g3)
  
  (define g4 (get-game net-id))
  (debug-game g4)
  )

(define (play-full-game game-file user1 pwd1 user2 pwd2)
  ; The reference game
  (define g-ref
    (without-logger (list-game->game (file->value game-file))))
  ; The game we will play through the network
  (define g0 (new network-game% [nb-cells (send g-ref get-nb-cells)]
                  [player1-class "Human"] [player2-class "Human"]
                  [player1-name user1] [player2-name user2]))
  (define net-id (new-game g0))
  (define plies (send g-ref get-plies))
  
  (log-debug "Beginning game\n\n")
  (for ([ply plies]
        [user (in-cycle (list user1 user2))]
        [pwd (in-cycle (list pwd1 pwd2))])
    (log-debug "Ply to play: ~a" ply)
    (set-user-password user pwd)
    (define g (get-game net-id))
    (log-debug "Current user: ~a\tuser: ~a" (send g get-current-name) user)
    (send g play-ply ply)
    (unless (send g new-ply?)
      (log-debug "Forcing end move")
      (send g play-move 'end))
    (debug-game g))
  
  (define g-end (get-game net-id))
  ; Check that the generated plies are the same as the initial game:
  (check-equal? (send g-end get-plies)
                plies))

(play-full-game "game1.twr" "plip" "plop" "plap" "plup")
(play-full-game "game2.twr" "plip" "plop" "plap" "plup")
(play-full-game "game3.twr" "plip" "plop" "plap" "plup")

#;(current-logger towers-lib-logger)

