# frozen_string_literal: true

require 'elasticsearch'
require 'faraday'
require 'json'
require 'base64'
require 'active_support/core_ext/hash'
require_relative 'elasticconfig'

# Elasticsearch registry for connectors
class ElasticRegistry < ElasticConfig
  def initialize
    super('ingest-connectors')
  end

  def register(id, info)
    write_key(id, info)
  end

  def unregister(id)
    existing = list.reject { |connector|
      connector[:key] == id
    }
    _update(existing)
  end
end
