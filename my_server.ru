require 'reel'
require 'celluloid'
require 'restclient'
require 'json'

require './lib/producer'
require './lib/consumer'

require './lib/sse'
require './lib/my_server'

MyServer.run
