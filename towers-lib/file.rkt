#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require "game.rkt"
         "base.rkt"
         racket/class
         racket/file
         )

(define (read-game [in (current-input-port)])
  (list-game->game (read in)))

(define (save-game file game)
  (write-to-file (send game game->list)
                 file
                 #:exists 'replace))

(define (load-game file)
  (and (file-exists? file)
       (list-game->game (file->value file))))

(define (save-current-game file) 
  (save-game file current-game))

(define (load-current-game file)
  (set-current-game (load-game file)))
