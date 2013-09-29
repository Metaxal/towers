#!/usr/bin/env racket
#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require towers-lib/base
         racket/cmdline
         racket/runtime-path
         (for-syntax racket/base)
         framework/splash
         )

(define-runtime-path splash-path
  (build-path "img" "splash.png"))

(define-runtime-module-path gui.rkt "gui.rkt")

(define-logger towers)

(current-logger towers-logger)
(command-line
 #:once-each
 [("-p" "--preferences") file
                         "Sets the preference file"
                         (pref-file (path->complete-path
                                     file
                                     (find-system-path 'orig-dir)))]
 [("-d" "--debug") "Shows debugging information"
                   (define tll-rc (make-log-receiver towers-lib-logger 'debug))
                   (define tlt-rc (make-log-receiver towers-logger 'debug))
                   (loop-receive tll-rc tlt-rc)])

(start-splash splash-path "Towers" 700)
(define gui-main (dynamic-require gui.rkt 'main))
(shutdown-splash)
(gui-main 'init)
(close-splash)

(gui-main 'show)
