# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'
require 'json'
require 'openssl'
require 'base64'
require 'active_support/core_ext/hash'

PUBLIC_KEY_FILE = File.join(File.dirname(__FILE__), 'certs', 'public_key.pem')
PRIVATE_KEY_FILE = File.join(File.dirname(__FILE__), 'certs', 'private_key.pem')

# Elasticsearch key-value storage with encryption abilities
class ElasticConfig
  def initialize(index = 'ingest-config')
    @client = Elasticsearch::Client.new(host: '0.0.0.0', user: 'elastic', password: 'changeme')
    @client.cluster.health
    @index = index
    @id = 1
    _create_index
    @pub_key = OpenSSL::PKey::RSA.new(File.read(PUBLIC_KEY_FILE))
    @priv_key = OpenSSL::PKey::RSA.new(File.read(PRIVATE_KEY_FILE))
  end

  def _create_index
    return if @client.indices.exists?(:index => @index)
    index_settings = { number_of_shards: 1, number_of_replicas: 0 }
    settings = { settings: { index: index_settings } }
    @client.indices.create(index: @index, body: settings)
    doc = { items: [], timestamp: Time.now }
    @client.index(index: @index, id: @id, body: doc, refresh: 'wait_for')
  end

  def _update(items = [])
    doc = { items: items, timestamp: Time.now }
    @client.update(index: @index, id: @id, body: { doc: doc }, refresh: 'wait_for')
  end

  def encrypt(data)
    "encrypted:#{b64enc(@pub_key.public_encrypt(data))}"
  end

  def decrypt(data)
    return data if @priv_key.nil?
    data = data.delete_prefix('encrypted:')
    data = Base64.decode64(data)
    @priv_key.private_decrypt(data)
  end

  def b64enc(data)
    Base64.encode64(data).delete("\n")
  end

  def list
    hits = @client.search(index: @index)['hits']['hits']
    return [] if hits.empty?

    items = hits[0]['_source'].deep_transform_keys(&:to_sym)[:items]
    items.nil? ? [] : items
  end

  def _decrypt(value)
    value = decrypt(value) if value.instance_of?(String) && value.start_with?('encrypted:')
    value
  end

  def read
    Hash[list.collect { |item|
      [item[:key].to_sym, _decrypt(item[:value])]
    }]
  end

  def read_key(key)
    read[key.to_sym]
  end

  def write_key(key, value, encrypted: false)
    key = key.to_s
    value = encrypt(value) if value.instance_of?(String) && encrypted
    value = value.deep_transform_keys(&:to_s) if value.instance_of?(Hash)
    if value.instance_of?(Array)
      value.map! { |item|
        item = item.deep_transform_keys(&:to_s) if item.instance_of?(Hash)
        item
      }
    end
    existing = list.reject { |item|
      item[:key] == key
    }
    item = { key: key, value: value }
    existing.push(item)
    _update(existing)
  end
end

# This version does not know how to decrypt but can encrypt using the pub key provided by an url
class ExternalElasticConfig < ElasticConfig
  def initialize(service)
    super()
    @pub_key = OpenSSL::PKey::RSA.new(Faraday.get("#{service}/public_key").body)
    @priv_key = nil
  end
end
