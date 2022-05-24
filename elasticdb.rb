# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'

require_relative 'events'

BATCH_SIZE = 100

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB
  def initialize
    @indices = Concurrent::Hash.new
    @client = Elasticsearch::Client.new(host: '0.0.0.0', user: 'elastic', password: 'changeme')
    puts(@client.cluster.health)
  end

  def purge
    # XXX threasafeness
    updates = creations = noops = 0

    @indices.each { |index, documents|
      # preparing a bulk batch
      body = []
      BATCH_SIZE.times {
        begin
          document = documents.deq(true)
        rescue ThreadError
          # empty
          break
        end
        break if document.nil?

        body.push({ update: { _index: index, _id: document[:_id] } })
        # XXX for now
        filtered_doc = {
          :summary => document[:summary],
          :listing_url => document[:listing_url],
          :name => document[:name],
          :country => document[:country]
        }
        body.push({ :doc => filtered_doc, :doc_as_upsert => true })
      }

      next if body.empty?

      # pushing the request
      begin
        resp = @client.bulk(body: body)
        resp['items'].each do |update|
          case update['update']['result']
          when 'noop'
            noops += 1
          when 'created'
            creations += 1
          when 'updated'
            updates += 1
          end
        end
      rescue Faraday::Error::ConnectionFailed
        puts('Whoops')
        raise
      end
    }
    { :created => creations, :updated => updates, :noop => noops }
  end

  def push(event)
    res = { :created => 0, :updated => 0, :noop => 0 }
    case event
    # XXX CHange event for now is just a new document + direct purge
    when ChangedEvent
      document = event.data[:document]
      index = event.data[:index]
      @indices[index] = Queue.new unless @indices.include?(index)
      @indices[index].push(document)
      res = purge
      puts(res)
    when AddEvent
      document = event.data[:document]
      index = event.data[:index]
      @indices[index] = Queue.new unless @indices.include?(index)
      @indices[index].push(document)
      res = purge if @indices[index].size >= BATCH_SIZE

    when FinishedEvent
      res = purge
    end
    res
  end

end

# This class can be used by a sync Job to read some configuration info
# Things like auth tokens, indexing rules, etc.
class ElasticConfig
  def read
    {
      auth_token: 'secret',
      indexing_rules: {
        index_target: 'airbnb',
        bedrooms: 2
      }
    }
  end
end
