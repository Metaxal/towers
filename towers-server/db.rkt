#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require (only-in towers-lib/connection encode-password current-user)
         towers-lib/base
         ;towers-lib/preferences
         bazaar/debug
         db/base
         db/mysql
         racket/list
         racket/string
         racket/dict
         racket/class
         )

(provide get-connection
         set-connection
         set-auto-connection
         close-connection
         get-salt
         verify-user
         create-user
         get-players
         create-game
         get-game-list
         get-current-game-list
         get-game-elos
         get-game
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

(define (get-pwd+salt user)
  (define pwd:salt
    (query-rows
     cnx
     "SELECT password, salt FROM users WHERE username=? AND isPlayer=1 AND block=0"
     user))
  (if (not (empty? pwd:salt))
      (apply values (vector->list (first pwd:salt)))
      (values #f #f)))

(define (get-salt user)
  (query-maybe-value 
   cnx
   "SELECT salt FROM users WHERE username=? AND isPlayer=1 AND block=0"
   user))

(define (verify-user user enc-pwd)
  (define-values (true-pwd salt) (get-pwd+salt user))
  (write (list enc-pwd true-pwd)) (newline)
  (and true-pwd
       (equal? true-pwd enc-pwd)))

(define (get-players)
  (query-list 
   cnx
   "SELECT username FROM users WHERE isPlayer=1 AND block = 0"))

(define (create-game user user1 user2 size full-game next-player)
  (write (list user user1 user2 size full-game next-player)) (newline)
  (define res
    (query
     cnx
     "INSERT INTO games (username1, username2, size, fullGame, nextPlayer, lastUpdateDate, winner) 
    VALUES (?, ?, ?, ?, ?, ?, '')"
     user1 user2 size full-game next-player (current-seconds)))
  (dict-ref (simple-result-info res) 'insert-id))

(define (get-game-list user [extra-cond ""])
  (query-rows
   cnx
   (string-append
    "SELECT gameID, size, username1, username2, lastUpdateDate, nextPlayer, winner
    FROM games WHERE (username1=? OR username2=?) "
    extra-cond)
   user user))

(define (get-current-game-list user)
  (get-game-list user "AND winner=''"))

(define (get-game user game-id)
  (define str
    (query-maybe-value 
     cnx
     "SELECT fullGame FROM games WHERE gameID=? AND (username1=? OR username2=?)"
     game-id user user))
  (and str
       (read (open-input-string str))))

(define (get-game-elos game-id)
  (query-rows
   cnx
   "SELECT username, elo FROM users, games 
    WHERE gameID=? AND (username=username1 OR username=username2)"
   game-id))

(define (update-elo user elo)
  (query-exec cnx "UPDATE users set elo=? WHERE username=?" elo user))

(define (update-game user game-id full-game next-player winner)
  (query-exec 
   cnx
   "UPDATE games set fullGame=?, nextPlayer=?, winner=?, lastUpdate=?
    WHERE gameID=? AND nextPlayer=?"
   full-game next-player winner (current-seconds) game-id user)
  )

(define (get-players-stats [start 0] [end 100])
  (query-rows
   cnx
   "SELECT username, elo FROM users WHERE isPlayer=1 AND block=0 ORDER BY elo DESC LIMIT ?,?"
   start end))

(define (create-user user pwd salt email)
  ; TODO: verify that the salt is complex, to avoid attacks to guess the random generator
  ;(check-salt)
  ;(check-email)
  (query-exec
   cnx
   "INSERT INTO users (name, username, email, password, salt, usertype, block, sendEmail, isPlayer, 
    gameNotifyEmail, elo)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
   user user email pwd salt "Registered" 0 1 1 1 1000))


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
  `username1`       varchar(100) NOT NULL,
  `username2`       varchar(100) NOT NULL,
  `size`            int(11) NOT NULL,
  `fullGame`        text NOT NULL,
  `nextPlayer`      varchar(100) NOT NULL,
  `lastUpdateDate`  int(11) NOT NULL,
  `finished`        tinyint(1) NOT NULL DEFAULT '0',
  `winner`          varchar(100) DEFAULT NULL,
  PRIMARY KEY (`gameID`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0")
  
  (query-exec cnx "CREATE TABLE IF NOT EXISTS `users` (
  `id`               int(11) NOT NULL AUTO_INCREMENT,
  `name`             varchar(255) NOT NULL DEFAULT '',
  `username`         varchar(150) NOT NULL DEFAULT '',
  `email`            varchar(100) NOT NULL DEFAULT '',
  `password`         varchar(100) NOT NULL DEFAULT '',
  `salt`             varchar(100) NOT NULL DEFAULT '',
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

(module+ test
  (require bazaar/rackunit)
  (load-preferences)
  (send prefs set 'database #f)
  (set-auto-connection #:read-preferences #f
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
