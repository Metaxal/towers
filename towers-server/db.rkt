#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require (only-in towers-lib/connection encode-password current-user make-salt)
         towers-lib/base
         ;towers-lib/preferences
         bazaar/debug
         db/base
         db/mysql
         racket/list
         racket/string
         racket/dict
         racket/class
         racket/format
         )

(provide get-connection
         set-connection
         set-auto-connection
         close-connection
         get-client-salt
         verify-user
         create-user
         get-players
         create-game
         get-game-list
         get-ask-game-list
         get-current-game-list
         get-game-elos
         get-game
         accept-game
         reject-game
         update-elo
         update-game
         get-players-stats
         create-database
         select-database
         create-towers-tables
         )

(define cnx #f) ; not a parameter to share the connection among all threads

(define (get-connection) cnx)

(define (close-connection)
  (when cnx
    (disconnect cnx)
    (set! cnx #f)))

;; notice-handler: same as for mysql-connect
;; See http://docs.racket-lang.org/db/using-db.html?q=db#%28part._intro-servlets%29
(define (set-connection user password [database #f]
                        #:notice-handler [notice-handler void])
  (close-connection)
  (set!
   cnx
   (virtual-connection
    (connection-pool
     (λ()(mysql-connect #:user user
                        #:password password
                        #:database database
                        #:notice-handler notice-handler))))))

;; Sets the connection from the preference file
;; notice-handler: same as for mysql-connect
(define (set-auto-connection #:notice-handler [notice-handler void])
  (set-connection (send prefs get 'mysql-user)
                  (send prefs get 'mysql-password)
                  (send prefs get 'database)
                  #:notice-handler notice-handler))

(define (disconnection)
  (disconnect cnx))

;; Returns the password and the server-salt if they exist.
(define (get-pwd+salt user)
  (define pwd:salt
    (query-maybe-row
     cnx
     "SELECT password, server_salt FROM users WHERE username = ? AND isPlayer = 1 AND block = 0"
     user))
  (if pwd:salt
      (apply values (vector->list pwd:salt))
      (values #f #f)))

(define (get-server-salt user)
  (query-maybe-value
   cnx
   "SELECT server_salt FROM users WHERE username = ? AND isPlayer = 1 AND block = 0"
   user))

(define (get-client-salt user)
  (query-maybe-value
   cnx
   "SELECT client_salt FROM users WHERE username = ? AND isPlayer = 1 AND block = 0"
   user))

;; Takes a password that is already encoded with the client-salt,
;; encodes it again with the server salt, and compares it with the
;; stored password.
(define (verify-user user pwd)
  (define-values (enc-pwd server-salt) (get-pwd+salt user))
  (and enc-pwd
       (equal? (encode-password pwd server-salt) enc-pwd)))

(define (get-players)
  (query-list
   cnx
   "SELECT username FROM users WHERE isPlayer=1 AND block = 0"))

(define (create-game user user1 user2 size full-game next-player)
  (define res
    (and
      (or (equal? user user1)
          (equal? user user2))
      (query
       cnx
       "INSERT INTO games (creator, username1, username2, size, fullGame, nextPlayer, 
          lastUpdateDate, winner)
        VALUES (?, ?, ?, ?, ?, ?, ?, '')"
       user user1 user2 size full-game next-player (current-seconds))))
  (dict-ref (simple-result-info res) 'insert-id))

(define (get-game-list-ex user [extra-cond ""] . extra-args)
  (apply
   query-rows
   cnx
   (string-append
    "SELECT gameID, size, creator, username1, username2, lastUpdateDate, nextPlayer, winner, accepted
    FROM games WHERE (username1 = ? OR username2 = ?) "
    extra-cond)
   user user
   extra-args))

;; Returns the list of games that have not be rejected, i.e. it includes games
;; asked for acceptance.
(define (get-game-list user)
  (get-game-list-ex user "AND accepted != 'no'"))

;; Same as get-game-list, but only games that are not finished yet.
(define (get-current-game-list user)
  (get-game-list-ex user "AND accepted != 'no' AND winner=''"))

;; Returns the list of games asking for acceptance by the user
(define (get-ask-game-list user)
  (get-game-list-ex user "AND accepted = 'ask' AND creator != ?" user))

(define (get-game user game-id)
  (define vec
    (query-maybe-row
     cnx
     "SELECT fullGame, accepted FROM games WHERE gameID = ? AND (username1 = ? OR username2 = ?)"
     game-id user user))
  (and vec
       (list (read (open-input-string (vector-ref vec 0)))
             (vector-ref vec 1))))

(define (accept-game user game-id [accepted "yes"])
  (query-exec 
   cnx
   "UPDATE games SET accepted = ? WHERE gameID = ? AND (username1 = ? OR username2 = ?)
    AND creator != ?"
   accepted game-id user user user))

(define (reject-game user game-id)
  (accept-game user game-id "no"))

(define (get-game-elos game-id)
  (query-rows
   cnx
   "SELECT username, elo FROM users, games
    WHERE gameID = ? AND (username = username1 OR username = username2)"
   game-id))

(define (update-elo user elo)
  (query-exec cnx "UPDATE users set elo = ? WHERE username = ?" elo user))

;; full-game is a scheme list
;; Only games that have been accepted can be updated
(define (update-game user game-id full-game next-player winner)
  (query-exec
   cnx
   "UPDATE games SET fullGame = ?, nextPlayer = ?, winner = ?, lastUpdateDate = ?
    WHERE gameID = ? AND nextPlayer = ? AND accepted = 'yes'"
   (~s full-game) next-player winner (current-seconds) game-id user)
  )

(define (get-players-stats [start 0] [end 100])
  (query-rows
   cnx
   "SELECT username, elo FROM users WHERE isPlayer = 1 AND block = 0 ORDER BY elo DESC LIMIT ?, ?"
   start end))

;; `pwd' must already be salted by `salt' (which is the client salt)
;; and will be salted again by a new server-side salt.
;; For a raw password on the client side, the client must request the client-salt,
;; encode the password with it, send the encoded password to the server,
;; which stores it encoded it again with a server-salt.
;; The client salt allows to avoid storing the password in clear text on the client and on the 
;; network, but does not prevent a MITM attack to get the encrypted password and use it to log
;; into the user's account.
;; The server salting avoids giving an attacker all access to all user accounts if the db is cracked.
(define (create-user user pwd client-salt email)
  ;(check-email)
  (define server-salt (make-salt))
  (set! pwd (encode-password pwd server-salt))
  (query-exec
   cnx
   "INSERT INTO users (name, username, email, password, client_salt, server_salt, usertype, block, 
   sendEmail, isPlayer, gameNotifyEmail, elo)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
   user user email pwd client-salt server-salt "Registered" 0 1 1 1 1000))


;==========================;
;=== Database Structure ===;
;==========================;

;; Use this function to build a correct mysql name, surrounded by backticks,
;; and making sure it does not include backticks.
(define (sql-name name)
  (string-append "`" (string-replace name "`" "") "`"))

(define (select-database name)
  (query-exec cnx (string-append "USE " (sql-name name))))

;; exists: boolean
(define (drop-database name #:if-exists? [if-exists? #f])
  (query-exec
   cnx
   (string-append "DROP DATABASE " (if if-exists? "IF EXISTS " "") (sql-name name))))

;; MySQL only?
;; More general: test
(define (database-exists? name)
  (not
    (empty?
     (query-list cnx "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = "
                 (sql-name name)))))

;; exists: (one-of 'error 'skip 'drop)
(define (create-database name
                         #:exists [exists 'error])
  (when (eq? exists 'drop)
    (drop-database name #:if-exists? #t))
  (query-exec
   cnx
   (string-append
    "CREATE DATABASE "
    (if (memq exists '(skip drop))
        "IF NOT EXISTS "
        "")
    (sql-name name)
    " DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci")))

(define (create-towers-tables)
  (query-exec cnx "CREATE TABLE IF NOT EXISTS `games` (
  `gameID`          int(11) NOT NULL AUTO_INCREMENT,
  `creator`         varchar(100) NOT NULL,
  `username1`       varchar(100) NOT NULL,
  `username2`       varchar(100) NOT NULL,
  `size`            int(11) NOT NULL,
  `fullGame`        text NOT NULL,
  `nextPlayer`      varchar(100) NOT NULL,
  `lastUpdateDate`  int(11) NOT NULL,
  `finished`        tinyint(1) NOT NULL DEFAULT '0',
  `winner`          varchar(100) DEFAULT NULL,
  `accepted`        enum('ask', 'yes', 'no') NOT NULL DEFAULT 'ask',
  PRIMARY KEY (`gameID`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0")

  (query-exec cnx "CREATE TABLE IF NOT EXISTS `users` (
  `id`               int(11) NOT NULL AUTO_INCREMENT,
  `name`             varchar(255) NOT NULL DEFAULT '',
  `username`         varchar(150) NOT NULL DEFAULT '',
  `email`            varchar(100) NOT NULL DEFAULT '',
  `password`         varchar(100) NOT NULL DEFAULT '',
  `client_salt`      varchar(100) NOT NULL DEFAULT '',
  `server_salt`      varchar(100) NOT NULL DEFAULT '',
  `usertype`         varchar(25) NOT NULL DEFAULT '',
  `block`            tinyint(4) NOT NULL DEFAULT '0',
  `sendEmail`        tinyint(4) DEFAULT '0',
  `isPlayer`         int(11) NOT NULL DEFAULT '1',
  `gameNotifyEmail`  int(11) NOT NULL DEFAULT '0',
  `elo`              int(11) NOT NULL DEFAULT '1000',
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY (`username`),
  KEY `usertype` (`usertype`),
  KEY `email` (`email`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0"))

(module+ drracket ;test
  ; These tests will fail if the preferences are not correctly setup
  ; hence the drracket submodule rather than the test submodule.
  (require bazaar/rackunit)
  (load-preferences)
  (set-connection 
   (send prefs get 'mysql-user)
   (send prefs get 'mysql-password)
   #f
   #:notice-handler 'error)

  (define db1 "test_db1_AUIEWWYI")

  ; Make sure the database exists, and SELECT it
  (check-not-fail (drop-database db1 #:if-exists? #t))
  (check-not-fail (create-database db1))
  (check-fail     (create-database db1))
  (check-not-fail (select-database db1))

  (check-fail (create-database db1))

  ; add a table to be sure it will be there after 'skip
  (check-not-fail (query-exec cnx "CREATE TABLE IF NOT EXISTS `table1` (
  `col1` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"))
  (check-not-fail (create-database db1 #:exists 'skip))
  ; table1 should still be here
  (check-not-fail (query cnx "SELECT * FROM table1"))

  ; then verify that the table gets dropped correctly:
  (check-not-fail (create-database db1 #:exists 'drop))
  ; table1 should not be here anymore
  (check-fail (query cnx "SELECT * FROM table1"))

  (check-fail (query cnx "SELECT AUIE FROM BZWXY"))

  ;(select-database "towers_test")
  ;(get-game-list "plip")
  )
