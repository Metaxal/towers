#!/usr/bin/env racket
#lang racket/base
;;; Copyright (C) Laurent Orseau, 2010-2013
;;; GNU General Public Licence 3 (http://www.gnu.org/licenses/gpl.html)

(require towers-lib/preferences
         bazaar/file
         (for-syntax bazaar/file)
         racket/runtime-path
         (for-syntax racket/base)
         framework/splash
         )

;; Include all interesting files as runtime paths:
#;(define-runtime-path-list
  include-file-paths
  (filter file-exists? ; only files, not directories
          (find-files-ex '(;#rx"^img[/\\\\]"
                           #rx"^img[/\\\\]replay[/\\\\]readme.txt"
                           #rx"^docs[/\\\\]"
                           )
                         ; ignore:
                         '(#rx"\\.svn" ; subversion subdirs
                           #rx"\\.git"
                           #rx"\\.unison"
                           #rx"^releases"
                           ; backup files:
                           #rx"\\.bak$" ; windows
                           #rx"~$" ; unix 
                           ; source files:
                           #rx"\\.ss$"
                           #rx"\\.rkt$"
                           #rx"\\.scrbl$"
                           )
                         )))


(define-runtime-path splash-path 
  (build-path "img" "splash.png"))

(define-runtime-module-path gui.rkt "gui.rkt")

(module+ main
  (require racket/cmdline)
  
  (command-line 
   #:once-any
   [("-p" "--preferences") file
                           "Sets the preference file"
                           (pref-file file)])
  
  (start-splash splash-path "Towers" 700)
  (define gui-main (dynamic-require gui.rkt 'main))
  (shutdown-splash)
  (gui-main 'init)
  (close-splash)
  
  (gui-main 'show))
