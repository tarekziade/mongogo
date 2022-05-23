# frozen_string_literal: true

require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

# Mongo backend
class MongoBackend
  def initialize
    @client = Mongo::Client.new(['127.0.0.1:27017'], database: 'sample_airbnb')
    puts(@client.summary)
  end

  def documents
    puts("Read mongo")
    # XXX yield, pagination
    @client[:listingsAndReviews].find
  end

  def close
    @client.close
  end
end
