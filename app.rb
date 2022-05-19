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
    # XXX move to Async::Reactor and use a single thread
    set :pool, Concurrent::ThreadPoolExecutor.new(min_threads: 3, max_threads: 10, max_queue: 0)
    set :results, Concurrent::Hash.new
    set :database, ElasticDB.new
    set :config, ElasticConfig.new
  end

  def quit!
    settings.pool.shutdown
    settings.pool.wait_for_termination
    super
  end

  def status_callback(job)
    puts("Job #{job.id} - #{job.status}")
    settings.results[job.id] = { :status => job.status }
  end

  get '/' do
    json(
      title: 'Hey, I ingest data from MongoDB, trigger me at http://localhost:9292/start'
    )
  end

  # when using Puma, this creates a new thread -- which is not required since
  # we handle our own thread for the sync job, but does not hurt
  get '/start' do
    job_id = SecureRandom.uuid
    data_source = MongoBackend.new
    job = SyncJob.new(job_id, data_source, method(:status_callback), settings.config)

    # data grabber
    settings.pool.post do
      puts("Running #{job.id} in a thread")
      job.run
    rescue StandardError => e
      puts(e.backtrace)
    end

    # dequeue worker
    settings.pool.post do
      puts('Running the dequeuer in a thread')
      begin
        loop do
          doc = job.documents_queue.pop(false)
          break if doc == 'FINISHED'
          # send in batches
          settings.database.write([doc])
        end
      rescue StandardError => e
        puts(e.backtrace)
      end
    end

    json(
      job_id: job_id,
      result_url: "http://localhost:9292/result/#{job_id}"
    )
  end

  get '/result/:job_id' do
    job_id = params[:job_id]
    unless settings.results.include?(job_id)
      status 404
      return json({ "Not found": job_id })
    end

    result = settings.results[job_id]
    if result[:status] == 'finished'
      result[:job].close
      result.delete(:job)
      settings.results.delete(job_id)
    end
    json(result)
  end
end
