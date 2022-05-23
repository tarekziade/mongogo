# frozen_string_literal: true
require_relative 'events'

FINISHED = 'finished'
WORKING = 'working'
INITIALIZED = 'initialized'

# handles jobs instances
class Jobs
  def initialize
    @jobs = Concurrent::Hash.new
  end

  def get_job(job_id)
    @jobs[job_id]
  end

  def run_job(data_source, event_callback, config)
    job = SyncJob.new(self, data_source, event_callback, config)
    @jobs[job.id] = job
    job.run
    job.id
  end

  def include?(job_id)
    @jobs.include?(job_id)
  end

  def status(job_id)
    @jobs[job_id].status
  end

  def end_job(job_id)
    # XXX other cleanup?
    @jobs.delete(job_id)
  end
end

# XXX move to Async::Reactor and use a single thread
# Handles a Sync Job. One thread grabs the data, and the other dequeues it
class SyncJob
  attr_reader :id, :status, :events_queue

  def initialize(manager, data_source, event_callback, configuration)
    @manager = manager
    @data_source = data_source
    @id = SecureRandom.uuid
    @events_queue = Queue.new
    @status = INITIALIZED
    @event_callback = event_callback
    @configuration = configuration
    @dequeuer = nil
    @fetcher = nil
  end

  def close
    puts(@dequeuer.status)
    puts(@fetcher.status)
    # XXX cleanup? close connections?
  end

  def finished
    @status == FINISHED
  end

  def print_exception(e)
    puts(e)
    puts(e.backtrace)
  end

  def run
    Thread.abort_on_exception = true

    @fetcher = Thread.new {
      begin
        fetch_data
      rescue StandardError => e
        print_exception(e)
      end
    }
    @dequeuer = Thread.new {
      begin
        dequeue
      rescue StandardError => e
        print_exception(e)
      end
    }
  end

  def dequeue
    loop do
      event = @events_queue.pop(false)
      # XXX send in batches
      @event_callback.call(event)
      break if event.instance_of?(FinishedEvent)
    end
    puts('Ingestion done.')
    @manager.end_job(@id)
  end

  def fetch_data
    @status = WORKING
    puts('Grabbing configuration')
    config = @configuration.read

    current = 0
    @data_source.documents.each do |doc|
      # filter!
      if !doc[:bedrooms].nil? && doc[:bedrooms] >= config[:indexing_rules][:bedrooms]
        @events_queue.push(AddEvent.new(@id, doc))
        current += 1
      end
    end

    @events_queue.push(FinishedEvent.new(@id))
    @status = FINISHED
    puts('Fetching done')
  end
end
