#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(provide (all-defined-out))

(require "base.rkt"
         racket/dict
         racket/list
         )

;;; In this file we define several specific rules that can modify the behavior
;;; of the game.
;;; (many are now outdated but I leave them because they can give ideas)

(define rules-dict
  '(
;    [no-lock          . "Pawns/towers are not locked when they capture an opponent's pawn/tower"]
;    [no-lock-master   . "The master pawn/tower is not locked when it captures an opponent's pawn/tower"]
    [tower-out        . "Pawns can get out of any tower, not just the master"]
;    [no-tower-out     . "Pawns cannot get out of a tower, except for the master."]
;    [no-lock-out      . "Pawns are not locked when they get out of a tower."]
;    [lock-master-out  . "When a pawn gets out of the master, the *master* gets locked"]
;    [still-tower-out  . "A pawn can get out of a tower only if it has not moved in the current ply"]
    ; with no-master-win and no-lock-master (requires tower-out): 
    ; avoids winning with the master by piercing the defense 
;    [lock-tower-out   . "Pawns moved out of towers (master or not) get locked"]
    ; makes splitting less powerfull
    [lock-after-move  . "Pawns/towers get locked after their move."]
;    [lock-raise-tower . "Raising a tower locks it (master or not)"]
    ; avoids building towers and attacking another tower in the same ply
;    [no-locked-raise  . "Cannot move a pawn/tower to a locked cell"]
    [lock-split-tower . "When taking a pawn out of a tower, lock the tower."]
    ;[no-lock-export   . "Exporting a pawn does NOT lock the master tower"]
    ;[no-lock-import   . "Importing a pawn does NOT lock the master tower"]
    ; makes import less powerfull.
    [import-first     . "Importing pawns can only be done at the beginning of the ply."]
    ; logical: 1) Import 2) Move 3) Export   
;    [import-one       . "Only one pawn can be imported by ply"]
    ; therefore exports (to raise move points) must be done carefully
;    [export-one       . "Only one pawn can be exported by ply"]
;    [export-now       . "Pawns are immediately exported to the reserve (no wait till the end of the ply)"]
    ; avoids problems of the number of pawns on the master 
    ; should be used with lock-raise-tower, 
;    [raise-one        . "Towers can only be raised by one pawn. The master tower cannot grow by more than one."]
    ;[no-first-export  . "The first player cannot export on the very first ply"]
    [no-first-lock-master . "Do not lock the master on the very first ply."]
    [master-at-corner . "The master is placed at the right corner."]
    ; makes them further from each other
    [no-master-win    . "The master cannot capture the opponent's master."]
    ; for no-lock-master: avois that the master pierces the defense to go straight to the master
    ))

(define (rule->string rule)
  (format "~a:\n\t~a" rule
          (dict-ref rules-dict rule)))

(define (rule->line-string rule)
  (format "~a: ~a" rule
          (dict-ref rules-dict rule)))

(define (specific-rule? rules rule)
  ; bug checking (raises an error if not found):
  (dict-ref rules-dict rule)
  (member rule rules))


;; If the rule applies, val must be true
;; (otherwise returns true)
(define (check-rule? rules rule val)
  (or (not (specific-rule? rules rule))
      val))

(define (check/raise-rule? rules rule val)
  (or (check-rule? rules rule val)
      (not (raise (error
                   (string-append "This action is not allowed because of the following rule:\n" 
                                  (rule->line-string rule)
                                  "\n"))))))
