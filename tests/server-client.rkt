#lang racket
(require (prefix-in db: towers-server/db)
         towers-server/server
         towers-lib/preferences
         towers-lib/connection
         towers-lib/game
         (only-in towers-server/db 
                  set-auto-connection 
                  get-connection
                  )
         bazaar/rackunit)

(define db-name "towers_test")

(read-preferences)
(set-pref 'database #f) ; the database may not exist yet.
(set-pref 'server-port "8081")
(game-server-port "8081")
(db:set-auto-connection #:read-preferences #f)

(db:create-database db-name #:exists 'drop)
(set-pref 'database db-name)
(db:select-database db-name)
(db:create-towers-tables)

;; Reset the connection, with the newly created database.
;; This is important because the server uses a connection pool,
;; with the default arguments for database, which (select-database may not always affect).
(db:set-connection 
 (get-pref 'mysql-user) (get-pref 'mysql-password)
 db-name
 #:notice-handler (λ(a b)(list a b))#;'error)

(init-connection #:read-preferences #f)

;(set-auto-connection)
;(set! cnx (get-connection))

(displayln "Starting server.")
; Do not init server, because we want to use the bd settings defined above
(thread (λ()(start-server #:read-preferences #f #:db-auto-connect #f)))
(sleep 3)
(displayln "Server started (hopefully).")

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

(define g (new game% [nb-cells 5] [player1-class "Human"] [player2-class "Human"]
               [player1-name "plap"] [player2-name "plip"]))
(check-equal? (new-game g) 1)
(check-equal? (new-game g) 2)
(let ([lg (get-game-list)])
  (check-equal? (length lg) 2)
  (check-pred (listof vector?) lg))
; Change user, verify that it sees the games too
(set-user-password "plip" "plop")
(check-equal? (length (get-game-list)) 2)
(check-pred list? (get-game 1))
