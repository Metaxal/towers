# Towers Server

## Install

On the command line:
```shell
raco pkg install towers-server
```
or enter `towers-server`  in the `File|Install Package...` menu option in DrRacket.

## Configure and run

On the first run of the server, you need to setup the preferences, then create the database, then run the server.
This can all be done in one command line:
```shell
racket -l towers-server -- --create-prefs --create-db
```

The server can be stopped with Ctrl-C.

If the server is stopped, you can now simply re-run it with:
```shell
racket -l towers-server
```

## Preferences

A default preference file is used.
If you wish to use a different preference file, you can specify it on the command line with the `-p` switch:
```shell
racket -l towers-server -- -p my-prefs.rktd 
```
Other switches can be added as above, for example to initialize the preferences of this file, and maybe create a new database.

By default, the preference file is the same for the server and the client, if they both run on the same machine by the same user.

Therefore you can simply first configure the server as in the previous section, specifying `localhost` for the address, then run the client with:
```shell
racket -l towers
```
and it should be connected to the server.

If you wish to use a different preference file, specify so with the `-p` switch for both the server and the client.
