# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'
require 'json'

require_relative 'events'

BATCH_SIZE = 100

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB
  MAPPING = JSON.load(File.read('dynamic_mapping.json'))

  def initialize
    @indices = Concurrent::Hash.new
    @client = Elasticsearch::Client.new(host: '0.0.0.0', user: 'elastic', password: 'changeme')
    puts(@client.cluster.health)
  end

  def purge
    # XXX threasafeness
    deletes = updates = creations = noops = 0

    @indices.each { |index, events|
      # preparing a bulk batch
      body = []
      BATCH_SIZE.times {
        begin
          event = events.deq(true)
        rescue ThreadError
          # empty
          break
        end

        doc_id = event.data[:document][:_id]

        case event
        when AddEvent, ModifyEvent, ChangedEvent
          document = event.data[:document]

          body.push({ update: { _index: index, _id: doc_id } })
          # XXX for now
          filtered_doc = {
            :summary => document[:summary],
            :listing_url => document[:listing_url],
            :name => document[:name],
            :country => document[:country]
          }
          body.push({ :doc => filtered_doc, :doc_as_upsert => true })
        when DeleteEvent
          body.push({ delete: { _index: index, _id: doc_id } })
        end
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
          when 'deleted'
            deletes += 1
          end
        end
      rescue Faraday::ConnectionFailed
        puts('Whoops')
        raise
      end
    }
    { :created => creations, :updated => updates, :noop => noops, :deleted => deletes }
  end

  def push(event)
    res = { :created => 0, :updated => 0, :noop => 0, :deleted => 0 }

    index = event.data[:index] if event.respond_to?(:data)
    if index && !@indices.include?(index)
      @indices[index] = Queue.new
      prepare_index(index)
    end

    case event
    when ChangedEvent
      @indices[index].push(event)
      res = purge

    when AddEvent, ModifyEvent, DeleteEvent
      @indices[index].push(event)
      res = purge if @indices[index].size >= BATCH_SIZE

    when FinishedEvent
      res = purge
    end
    res
  end

  # XXX batch+scale
  def get_existing_ids(index)
    return [] unless @client.indices.exists?(:index => index)
    # no batching for now
    @client.search(index: index, _source: ['id'], size: 2000)['hits']['hits'].map do |hit|
      hit['_id']
    end
  end

  def prepare_index(index)
    # push dynamic mapping template to index
    # or create index in case it does not exist
    if @client.indices.exists?(:index => index)
      @client.indices.put_mapping(
        :index => index,
        :body => MAPPING
      )
    else
      @client.indices.create(
        :index => index,
        :body => {
          :mappings => MAPPING
        }
      )
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
