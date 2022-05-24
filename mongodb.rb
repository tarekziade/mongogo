# frozen_string_literal: true

require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

# Mongo backend
class MongoBackend
  def initialize
    @client = Mongo::Client.new(['127.0.0.1:27021'],
                                :connect => :direct,
                                :database => 'sample_airbnb')

    puts("Existing Databases #{@client.database_names}")
    puts('Existing Collections')
    @client.collections.each { |coll| puts coll.name }
  end

  def documents
    collection = @client[:listingsAndReviews]

    # XXX yield, pagination, bulk read?
    collection.find
  end

  def close
    @client.close
  end

  def change_stream
    @client[:listingsAndReviews].watch.to_enum
  end
end
