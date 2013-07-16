# -*- encoding: UTF-8 -*-

class MyServer < Reel::Server
  include Celluloid::Logger

  HEADERS = { 'Content-Type' => 'text/event-stream', 'Transfer-Encoding' => 'chunked' }

  def initialize(host = '0.0.0.0', port = 9000)
    info("Server starting at #{host}:#{port}")

    super(host, port, &method(:on_connection))

    @connections = []

    @supervisor = Producer.supervise_as :producer
    @producer = Celluloid::Actor[:producer]
    @producer.async.retrieve
    @consumer = Consumer.pool args: [ @producer.flights ]
  end

  def on_connection(connection)
    while request = connection.request
      info("Client requested: #{request.method} #{request.url}")

      case request.url
      when '/details'
        handle_details(request)
      when '/refresh'
        handle_refresh(request)
      when '/subscribe'
        handle_subscription(connection)
      when '/wall'
        broadcast_message(request)
      when '/'
        handle_index(connection)
      end
    end
  end

  def handle_details(websocket)
    flight_number = websocket.read

    args = @consumer.filter flight_number

    websocket << args.to_json
  ensure
    websocket.close
  end

  def handle_refresh(websocket)
    @producer.async.retrieve

    message = "Flights refresh requested at #{Time.now}"
    websocket << { message: message }.to_json
    websocket.close

    @connections.each do |connection|
      begin
        wall_message(connection, message)
      rescue IOError, Errno::EPIPE, Errno::ECONNRESET
        @connections.delete(connection)
      end
    end

    async.broadcast_flights
  end

  def broadcast_flights
    while (flights = @producer.flights).empty?
      sleep(5)
    end

    @connections.each do |connection|
      begin
        sse_flights(connection, flights)
      rescue IOError, Errno::EPIPE, Errno::ECONNRESET
        @connections.delete(connection)
      end
    end
  end

  def handle_subscription(connection)
    @connections << connection

    connection.detach ; connection.respond(:ok, HEADERS)

    while (flights = @producer.flights).empty?
      sleep(5)
    end

    sse_flights(connection, flights)
  end

  def broadcast_message(websocket)
    message = websocket.read

    info("Replicating messages to all clients...")

    @connections.each do |connection|
      begin
        info("Sending message to #{connection}")

        wall_message(connection, message)
      rescue IOError, Errno::EPIPE, Errno::ECONNRESET => e
        error("Failed to write on #{connection}: #{e}")
        @connections.delete(connection)
      end
    end
  end

  def handle_index(request)
    request.respond(:ok, File.read('./public/index.html'))
  end

  private

  def sse_flights(connection, flights)
    sse = SSE.new(connection)
    args = { flights: flights }
    sse.write(args, event: 'flights-updated')
  end

  def wall_message(connection, message)
    sse = SSE.new connection
    args = { message: message }
    sse.write(args, event: 'message-received')
  end
end

