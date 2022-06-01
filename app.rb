#
# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#

# frozen_string_literal: true

require 'active_support/inflector'
require 'faraday'
require 'hashie'
require 'json'
require 'concurrent'

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/json'

require_relative 'job'
require_relative 'elasticdb'
require_relative 'elasticconfig'
require_relative 'elasticregistry'
require_relative 'mongodb'

# Sinatra app
class SyncService < Sinatra::Base
  register Sinatra::ConfigFile

  config_file File.join(__dir__, 'config.yml')

  configure do
    set :raise_errors, false
    set :show_exceptions, false
    set :bind, settings.http['host']
    set :port, settings.http['port']
    set :jobs, Jobs.new
    set :database, ElasticDB.new
    set :config, ElasticConfig.new
    set :registry, ElasticRegistry.new
    set :public_folder, File.join(File.dirname(__FILE__), 'html')
    set :status, { :jobs => {} }
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end

  get '/connectors' do
    json(settings.registry.list)
  end

  get '/status' do
    statuses = settings.config.read_key(:syncStatus)
    if statuses.nil?
      settings.config.write_key(:syncStatus, [])
      return json({})
    end
    statuses = settings.config.read_key(:syncStatus)
    statuses = { 'statuses': statuses } if statuses.nil?
    json(statuses)
  end

  post '/start' do
    pub_key = ''
    settings.registry.list.each do |connector|
      pub_key = connector[:value][:pub_key]
    end
    config = ExternalElasticConfig.new(pub_key)

    job = {
      :elasticSearchIndex => params[:elasticSearchIndex],
      :mongoDatabase => params[:mongoDatabase],
      :mongoPassword => params[:mongoPassword],
      :streamSync => params[:streamSync] == 'on',
      :type => 'bulk'
    }

    # triggering the job
    config.write_key(:syncJobs, [job], encrypted: true)
    redirect('/status.html')
  end
end
