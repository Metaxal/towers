#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require "../towers-lib/connection.rkt")

;; Don't forget to open the sever first!

(init-connection)
(set-user-password "plip" "plop")
(get-players)
(get-current-game-list)
