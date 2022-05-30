# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'
require 'json'
require 'openssl'
require 'uri'
require 'base64'
require 'active_support/core_ext/hash'

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
    @mutex = Mutex.new
  end

  def purge
    @mutex.synchronize do
      _purge
    end
  end

  def _purge
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
          filtered_doc = document.except(:_id).merge(id: doc_id)
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

# use OpenSSL::Cipher::AES.new(256, :CBC).random_key and random_iv to generate those
# then base64
DEFAULT_ENCRYPTION_KEY = '4bJmcAD0DW1wlUJ9epf2TwRn02nSRpKLiThYj07uPEg='
DEFAULT_ENCRYPTION_IV = 'FN0qvggzrsp8Fuji2s1ktA=='

# This class can be used by a sync Job to read some configuration info
# Things like auth tokens, indexing rules, etc.
class ElasticConfig
  def initialize(encryption_key: DEFAULT_ENCRYPTION_KEY, encryption_iv: DEFAULT_ENCRYPTION_IV)
    @client = Elasticsearch::Client.new(host: '0.0.0.0', user: 'elastic', password: 'changeme')
    @client.cluster.health
    @index = 'ingest-config'
    @id = 1
    @client.index(index: @index, id: @id, body: {}) unless @client.indices.exists?(:index => @index)
    @cipher_key = Base64.decode64(encryption_key)
    @cipher_iv = Base64.decode64(encryption_iv)
  end

  def encrypt(data)
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = @cipher_key
    cipher.iv  = @cipher_iv
    encrypted = cipher.update(data) + cipher.final
    "encrypted:#{b64enc(encrypted)}"
  end

  def decrypt(data)
    data = data.delete_prefix('encrypted:')
    data = Base64.decode64(data)
    decipher = OpenSSL::Cipher.new('aes-256-cbc')
    decipher.decrypt
    decipher.key = @cipher_key
    decipher.iv = @cipher_iv
    decipher.update(data) + decipher.final
  end

  def b64enc(data)
    Base64.encode64(data).delete("\n")
  end

  def read
    @client.search(index: @index)['hits']['hits'][0]['_source'].deep_transform_keys(&:to_sym).map { |key, value|
      value = decrypt(value) if value.instance_of?(String) && value.start_with?('encrypted:')
      [key, value]
    }.to_h
  end

  def read_key(key)
    value = read[key]
    value = decrypt(value) if value.start_with?('encrypted:')
    value
  end

  def write_key(key, value, encrypted: false)
    value = encrypt(value) if encrypted
    @client.update(index: @index, id: @id, body: { doc: { key => value } }, refresh: 'wait_for')
  end
end
