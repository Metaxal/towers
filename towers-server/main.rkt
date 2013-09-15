#lang racket/base

(require "server.rkt"
         towers-lib/base
         racket/cmdline)

(parameterize ([current-logger towers-server-logger])
  (command-line
   #:once-each
   [("-p" "--preferences") file
                           "Sets the preference file"
                           (pref-file file)]
   [("--create-db") "Creates Towers database with empty tables if it does not exist"
                    (create-towers-database)]
   [("--create-prefs") "Ask for the default preferences and creates or modifies the preferences file"
                       (create-preferences)]
   [("--exit") "Does not run the server and exits immediately"
                    (exit)]
   #:args ()
   (run-server)
   ))
