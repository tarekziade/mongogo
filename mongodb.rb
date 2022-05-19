# frozen_string_literal: true

require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

# Mongo backend
class MongoBackend
  def initialize
    @client = Mongo::Client.new(['127.0.0.1:27017'], database: 'sample_airbnb')
  end

  def documents
    puts('Calling Mongo')
    # XXX yield, pagination
    @client[:listingsAndReviews].find
  end

  def close
    @client.close
  end
end
