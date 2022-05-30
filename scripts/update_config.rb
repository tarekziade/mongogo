# frozen_string_literal: true

require_relative '../elasticdb'

config = ExternalElasticConfig.new('http://localhost:9292')
config.write_key('auth_token', 'modified_secret', encrypted: true)

puts(config.read)
