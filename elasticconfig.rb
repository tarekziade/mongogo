# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'
require 'json'
require 'openssl'
require 'uri'
require 'base64'
require 'active_support/core_ext/hash'


PUBLIC_KEY_FILE = File.join(File.dirname(__FILE__), 'certs', 'public_key.pem')
PRIVATE_KEY_FILE = File.join(File.dirname(__FILE__), 'certs', 'private_key.pem')

# Elasticsearch key-value storage with encryption abilities
class ElasticConfig
  def initialize
    @client = Elasticsearch::Client.new(host: '0.0.0.0', user: 'elastic', password: 'changeme')
    @client.cluster.health
    @index = 'ingest-config'
    @id = 1
    @client.index(index: @index, id: @id, body: {}) unless @client.indices.exists?(:index => @index)
    @pub_key = OpenSSL::PKey::RSA.new(File.read(PUBLIC_KEY_FILE))
    @priv_key = OpenSSL::PKey::RSA.new(File.read(PRIVATE_KEY_FILE))
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

# This version does not know how to decrypt but can encrypt using the pub key provided by an url
class ExternalElasticConfig < ElasticConfig
  def initialize(service)
    super()
    @pub_key = OpenSSL::PKey::RSA.new(Faraday.get("#{service}/public_key").body)
    @priv_key = nil
  end
end
