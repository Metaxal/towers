#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

#| Connection to server for games

This module provides functions to
synchronise game files with a server.
(there must of course be a special server for that).

To authenticate a user, first the salt is requested to the server given a username.
The password is then encrypted (hashed and salted) on the client before being sent.
The password thus does NOT travel in plain text.

|#

(provide make-salt
         encode-password
         server-address
         server-port
         server-root-path
         server-version
         current-user
         set-user-password
         check-authentication
         create-user
         accept-game
         reject-game
         get-game-list
         get-ask-game-list
         get-current-game-list
         update-game
         get-game
         new-game
         get-players
         )

(require "base.rkt"
         bazaar/debug
         racket/list
         racket/class
         racket/port
         racket/match
         racket/contract
         racket/format
         net/uri-codec
         net/url
         net/base64
         file/md5
         )

;; Generates a new salt,
;; but it's not clear that this has the correct cryptographic properties.
;; DOES not generate strings of 32 chars?
(define/contract (make-salt [n 32])
  (() (number?) . ->* . string?)
  (bytes->string/utf-8
   (base64-encode
    (list->bytes
     (build-list n (λ(n)(random 256))))
    "")))

(define (encode-password pwd [salt #f])
  (unless salt (set! salt (get-salt)))
  (bytes->string/utf-8
   (md5 (string-append pwd salt))))

(define (set-current-password pwd [salt #f])
  (current-password (encode-password pwd salt)))

(define (set-user-password l p [salt #f])
  (current-user l)
  (set-current-password p salt))

(define/contract (do-action action [other-query '()])
  ([string?] [(listof (cons/c symbol? string?))] . ->* . any)
  (define query
    (append other-query
            `((user     . ,(current-user))
              (password . ,(current-password))
              (version  . ,(server-version))
              (action   . ,action))))
  (define u
    (url
     "http" #f (server-address) (server-port) #t
     (list (path/param (server-root-path) '())
           (path/param (server-version) '()))
     query
     #f))
  (log-debug "Url: ~v" (url->string u))
  (define response
    (call/input-url u get-pure-port (λ(p)(port->list read p))))
  (log-debug "Received response:~v" response)
  (match response
    [(list `'(Error ,args ...))
     (apply error "Server error:" args)]
    [(list `',val) val]
    [(list val) val]
    [else (error "Unknown server error: unknown value:" response)]))

(define/contract (create-user user pwd-txt email)
  (string? string? string? . -> . any)
  (define salt (make-salt))
  (set-user-password user pwd-txt salt)
  (do-action "newuser" `((salt  . ,salt)
                         (email . ,email))))

(define/contract (get-game-list)
  (-> (listof vector?))
  (do-action "listgames"))

(define/contract (get-current-game-list)
  (-> (listof vector?))
  (do-action "listcurrentgames"))

(define/contract (get-ask-game-list)
  (-> (listof vector?))
  (do-action "listaskgames"))

(define/contract (get-game id)
  (number? . -> . (or/c #f (is-a?/c game<%>)))
  (define lg (do-action "getgame" `((gameid . ,(number->string id)))))
  #;(log-debug "Received by get-game: ~v" lg)
  (and lg (list? lg)
       (list-game->game lg #:network-game-id id)))

(define/contract (new-game g)
  ((is-a?/c game<%>) . -> . number?)
  (do-action "newgame"
             `((user1 . ,(send g get-name1))
               (user2 . ,(send g get-name2))
               (size  . ,(number->string (send g get-nb-cells)))
               (game  . ,(~s (send g game->list))))))

(define/contract (accept-game id)
  (number? . -> . any)
  (do-action "acceptgame" `((gameid . ,(number->string id)))))

(define/contract (reject-game id)
  (number? . -> . any)
  (do-action "rejectgame" `((gameid . ,(number->string id)))))

; Should add finished, winner, etc. ?
(define/contract (update-game game-id ply);game next-player winner
  (number? list? . -> . any)
  (do-action "updategame"
             `((gameid . ,(number->string game-id))
               (ply    . ,(~s ply)))))

(define (get-players)
  (do-action "getplayers"))

(define (get-salt)
  (do-action "getsalt"))

(define (check-authentication)
  (not (not (do-action "checkauth"))))

;;; See tests/connection.rkt for some tests
