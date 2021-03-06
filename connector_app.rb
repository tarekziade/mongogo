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

require_relative 'job'
require_relative 'elasticdb'
require_relative 'elasticconfig'
require_relative 'elasticregistry'
require_relative 'mongodb'

FORM = %q(
<div class="container">
   <form action="/start" method="POST">
  <div class="form-group">
    <label for="elasticSearchIndex">Elasticsearch Index</label>
    <input name="elasticSearchIndex" type="text" class="form-control" id="elasticSearchIndex" aria-describedby="elasticSearchIndex" value="search-airbnb" placeholder="search-airbnb">
    <small id="elasticSearchIndex" class="form-text text-muted">Target Elasticsearch index.</small>
  </div>
  <div class="form-group">
    <label for="mongoDatabase">MongoDB Collection</label>
    <input type="text" name="mongoDatabase" class="form-control" id="mongoDatabase"
    aria-describedby="mongoDatabase" placeholder="sample_airbnb" value="sample_airbnb">
    <small id="mongoDatabaseHelp" class="form-text text-muted">Source MongoDB Database</small>
  </div>
  <div class="form-group">
    <label for="mongoPassword">MongoDB Password</label>
    <input name="mongoPassword" type="password" class="form-control" id="mongoPassword">
  </div>
  <div class="form-group">
    <label for="filterDSL">Fields Filtering Rules</label>
    <textarea class="form-control" id="filters" rows="3">'bedrooms' >= 2</textarea>
  </div>
  <div class="form-group form-check">
    <input type="checkbox" name="streamSync" class="form-check-input" id="streamSync" checked>
    <label class="form-check-label" for="streamSync">Continuous Sync with Change Streams</label>
  </div>
  <button type="submit" class="btn btn-primary">Start Syncing</button>
  </form>
    </div>
)

# Connectors app
class ConnectorService

  def initialize
    @name = 'mongodb'
    @id = SecureRandom.uuid
    @jobs = Jobs.new
    @database = ElasticDB.new
    @registry = ElasticRegistry.new
    @config = ElasticConfig.new
    @status = { :jobs => {} }
    @pub_key = File.open(File.join(File.dirname(__FILE__), 'certs', 'public_key.pem'), &:read)
    puts('Register as connector for MongoDB')
    @registry.register(@id,
                       { 'name': @name,
                         'title': 'MongoDB Connector',
                         'description': 'Feed your Elasticsearch cluster with fresh data from MongoDB.',
                         'form': FORM,
                         'pub_key': @pub_key
                       })
    @called_back = false
  end

  def event_callback(event)
    @called_back = true
    res = @database.push(event)

    job_id = event.job_id
    job = @jobs.get_job(job_id)

    if event.instance_of?(FinishedEvent)
      job.close
      @status[:jobs].delete(job_id)
    else
      @status[:jobs][job_id] = job.to_json
    end
    res
  end

  def start_jobs(jobs)
    jobs.each do |job|
      start_job(job)
    end
  end

  def start_job(job)
    mongo_database = MongoBackend.new(job[:mongoDatabase])
    index = job[:elasticSearchIndex]
    existing_ids = @database.get_existing_ids(index)
    @jobs.run_bulk_sync(mongo_database, method(:event_callback), job, existing_ids)
  end

  def run
    Thread.abort_on_exception = true
    puts('Status Thread updater started')
    Thread.new {
      begin
        loop do
          if @called_back
            @config.write_key(:syncStatus, { statuses: @status, timestamp: Time.now })
            @called_back = false
          end
          sleep(0.5)
        end
      rescue StandardError => e
        puts(e)
        puts(e.backtrace)
      end
    }

    puts('Listening to jobs')
    loop do
      jobs = @config.read_key(:syncJobs)
      @config.write_key(:syncJobs, [])    # immediatly remove them
      start_jobs(jobs) unless jobs.nil?
      sleep(0.1)
    end
  rescue Interrupt
    puts('Unregister')
    @registry.unregister(@id)
    puts('Bye')
  end
end

service = ConnectorService.new
service.run
