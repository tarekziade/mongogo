# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'

require_relative 'events'

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB
  def initialize
    @indices = Concurrent::Hash.new
  end

  def purge
    puts('Bulk update')
    # XXX threasafeness
    @client = Elasticsearch::Client.new(log: true, user: 'elastic', password: 'changeme')
    puts(@client.cluster.health)
    @client.transport.reload_connections!

    @indices.each { |index, documents|
      puts("Updating index #{index} with #{documents.size} documents")
      num = 1
      documents.each_slice(10) { |batch|
        puts("Batch #{num} - 10 docs")

        body = []
        batch.each { |document|
          body.push({ index: { "_index": index, "_type": 'Airbnb' } })
          # XXX for now
          filtered_doc = { :summary => document[:summary], :listing_url => document[:listing_url], :name => document[:name] }
          body.push(filtered_doc)
        }
        puts(body)
        begin
          puts(@client.bulk(body: body))
        rescue Faraday::Error::ConnectionFailed => e
          puts('Whoops')
          raise
        end
        num += 1
        puts('OK')
      }
    }

    puts('Bulk update done')
  end

  def push(event)
    case event
    when AddEvent
      document = event.data[:document]
      index = event.data[:index]
      @indices[index] = [] unless @indices.include?(index)
      @indices[index].push(document)
    when FinishedEvent
      purge
    end
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
