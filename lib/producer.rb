# -*- encoding: UTF-8 -*-

class Producer
  include Celluloid, Celluloid::Logger

  attr_reader   :flights
  attr_accessor :terminate

  def initialize
    @flights = []
    @terminate = false
  end

  def retrieve
    info("Trying to get all flights in Brazil. Thread #{Thread.current}")

    url = 'http://planefinder.net/endpoints/update.php?faa=1&_=1373392058656'
    response = RestClient.get(url, { 'X-REQUESTED-WITH' => 'XmlHttpRequest' })
    json = JSON.parse(response)

    info("Flights retrieved, time to serialize them.")

    prefixes = %w(PR PT)
    flights = json['planes'].collect do |row|
      row.values.select do |entry|
        flights = prefixes.map { |p| entry if entry[1].start_with?(p) }
        flights.any?
      end
    end.flatten(1)

    @flights = flights.collect do |row|
      {
        plane_model:        row[0],
        registration:       row[1],
        flight_full_number: row[2],
        lattitude:          row[3],
        longitude:          row[4],
        altitude:           row[5],
        course:             row[6],
        speed:              row[7],
        company:            row[9],
        flight_number:      row[10],
        route:              row[11],
      }
    end

    info("Successfully retrieved flights.")
  rescue Exception => e
    error("Failed while trying to retrieve: #{e}")
  end
end

