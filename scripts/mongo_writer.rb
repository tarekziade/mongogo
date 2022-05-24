# frozen_string_literal: true
require 'mongo'
require 'faker'

client = Mongo::Client.new(['127.0.0.1:27021'],
                           :connect => :direct,
                           :database => 'sample_airbnb')

collection = client[:listingsAndReviews]

doc_id = rand.to_s[2..11]

doc = {
          :summary => Faker::Movies::Lebowski.quote,
          :listing_url => "https://www.airbnb.com/rooms/#{doc_id}",
          :name => Faker::Coffee.origin,
          :country => 'France',
          :_id => doc_id
        }

collection.insert_one(doc)
