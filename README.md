Reel Example
============

This project is a proof-of-concept using Reel as webserver and contains (obviously) a webchat example, using Server-Side Events (SSE) and WebSockets.

It also includes a PlaneFinder crawler that asynchronously loads all Brazilian flights and broadcast to connected clients.

Dependencies
============

* reel
* rest-client

Usage
=====

    $ bundle install --path vendor/bundle
    $ bundle exec rackup -s reel -o 0.0.0.0 -p 9000 my_server.ru

Authors
=======

* Marcelo Correia Pinheiro - <http://salizzar.net/>

TODO
====

* Create a decent interface
* Add callback to broadcast when all flights are retrieved, instead of while/sleep
* Minor refactorings

License
=======

Reel Example is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.
