#lang racket/base

(require "server.rkt"
         towers-lib/base
         racket/cmdline
         racket/class)

(parameterize ([current-logger towers-server-logger])
  (load-preferences)
  (command-line
   #:once-each
   [("-p" "--preferences") file
                           "Sets the preference file"
                           (pref-file file)
                           (send prefs clear)
                           (load-preferences)]
   [("--create-user") user pwd email
                      "Adds a new user to the database"
                      (create-user/cmd-line user pwd email)]
   [("--create-db") "Creates Towers database with empty tables if it does not exist"
                    (create-towers-database)]
   [("--create-prefs") "Ask for the default preferences and creates or modifies the preferences file"
                       (create-preferences)]
   [("--exit") "Does not run the server and exits immediately"
               (exit)]
   #:args ()
   (run-server)
   ))
