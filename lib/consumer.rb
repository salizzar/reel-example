# -*- encoding: UTF-8 -*-

class Consumer
  include Celluloid, Celluloid::Logger

  def initialize(flights)
    @flights = flights
  end

  def filter(flight_number)
    info("Trying to filter by flight number. Thead #{Thread.current}")

    @flights.detect { |entry| entry[:flight_full_number] == flight_number } || {}
  rescue Exception => e
    error("Failed while trying to retrieve: #{e}")
  end
end

