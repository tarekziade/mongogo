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
    set :public_folder, File.join(File.dirname(__FILE__), 'html')
    set :status, { :jobs => {} }
  end

  def event_callback(event)
    res = settings.database.push(event)
    job_id = event.job_id
    job = settings.jobs.get_job(job_id)

    if event.instance_of?(FinishedEvent)
      job.close
      settings.status[:jobs].delete(job_id)
    else
      settings.status[:jobs][job_id] = job.to_json
    end
    res
  end

  get '/public_key' do
    content_type 'text/plain'

    File.open(File.join(File.dirname(__FILE__), 'certs', 'public_key.pem')) do |file|
      file.read
    end
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end

  get '/status' do
    # XXX need to add job id
    json(settings.status)
  end

  # when using Puma, this creates a new thread -- which is not required since
  # we handle our own thread for the sync job, but does not hurt
  get '/start' do
    data_source = MongoBackend.new

    # to be batched, and need to find a spot
    index = settings.config.read[:indexing_rules][:index_target]
    existing_ids = settings.database.get_existing_ids(index)

    settings.jobs.run_bulk_sync(data_source, method(:event_callback), settings.config, existing_ids)
    redirect('/status.html')
  end

  get '/result/:job_id' do
    job_id = params[:job_id]
    unless settings.jobs.include?(job_id)
      status 404
      return json({ "Not found": job_id })
    end

    json(
      status: settings.jobs.status(job_id),
      job_id: job.id
    )
  end
end
