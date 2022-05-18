# frozen_string_literal: true

require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

# Populate with mongosh
# $ mongo testdb
# db.cars.insert({name: "Audi", price: 52642})
# db.cars.insert({name: "Mercedes", price: 57127})
# db.cars.insert({name: "Skoda", price: 9000})
# db.cars.insert({name: "Volvo", price: 29000})
# db.cars.insert({name: "Bentley", price: 350000})
# db.cars.insert({name: "Citroen", price: 21000})
# db.cars.insert({name: "Hummer", price: 41400})
# db.cars.insert({name: "Volkswagen", price: 21600})

# Mongo backend
class MongoBackend
  def initialize
    @client = Mongo::Client.new(['127.0.0.1:27017'], database: 'testdb')
  end

  def documents
    puts('Calling Mongo')
    # XXX yield, pagination
    @client[:cars].find
  end

  def close
    @client.close
  end
end
