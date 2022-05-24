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
  end

  def event_callback(event)
    res = settings.database.push(event)
    job = settings.jobs.get_job(event.job_id)
    puts(job.to_s) unless job.finished

    if event.instance_of?(FinishedEvent)
      job.close
      nil
    end
    res
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end

  # when using Puma, this creates a new thread -- which is not required since
  # we handle our own thread for the sync job, but does not hurt
  get '/start' do
    data_source = MongoBackend.new
    job_id = settings.jobs.run_bulk_sync(data_source, method(:event_callback), settings.config)

    json(
      job_id: job_id,
      result_url: "http://localhost:9292/result/#{job_id}"
    )
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
