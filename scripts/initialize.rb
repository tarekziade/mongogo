# frozen_string_literal: true

require_relative '../elasticdb'

config = ElasticConfig.new
config.write_key('auth_token', 'secret')
config.write_key('indexing_rules', {'index_target': 'airbnb', 'bedrooms': 2})

puts(config.read)

