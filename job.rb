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

  def run_bulk_sync(data_source, event_callback, config, existing_ids)
    job = BulkSync.new(self, data_source, event_callback, config, existing_ids)
    @jobs[job.id] = job
    job.run
    job.id
  end

  def run_stream_sync(data_source, event_callback, config)
    job = StreamSync.new(self, data_source, event_callback, config)
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
class BulkSync
  attr_reader :id, :status, :events_queue

  def initialize(manager, data_source, event_callback, configuration, existing_ids)
    @manager = manager
    @data_source = data_source
    @id = SecureRandom.uuid
    @events_queue = Queue.new
    @status = INITIALIZED
    @event_callback = event_callback
    @configuration = configuration
    @dequeuer = nil
    @fetcher = nil
    @existing_ids = existing_ids
    @fetched = 0
    @created = 0
    @updated = 0
    @noop = 0
    @deleted = 0
    @config = @configuration.read
    @index = @config[:indexing_rules][:index_target]
  end

  def to_s
    "Job #{@id[0..7]}/#{@status} ~ extracted #{@fetched} ~ created #{@created} ~ updated #{@updated} ~ noop #{@noop}"
  end

  def to_json(*_args)
    {
      :extracted => @fetched,
      :created => @created,
      :updated => @updated,
      :noop => @noop,
      :deleted => @deleted
    }
  end

  def close
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
      res = @event_callback.call(event)
      @created += res[:created]
      @updated += res[:updated]
      @noop += res[:noop]
      break if event.instance_of?(FinishedEvent)
    end
    puts(self)
    puts('Ingestion done.')
    @manager.end_job(@id)
    puts('Now starting the Stream')
    @manager.run_stream_sync(@data_source, @event_callback, @configuration)
  end

  def fetch_data
    @status = WORKING
    puts('Grabbing configuration')
    config = @configuration.read
    index = config[:indexing_rules][:index_target]
    current = 0
    seen_ids = []
    @data_source.documents.each do |doc|
      doc_id = doc[:_id]
      seen_ids.push(doc_id)
      event_klass = @existing_ids.include?(doc_id) ? AddEvent : ModifyEvent
      # filter!
      if !doc[:bedrooms].nil? && doc[:bedrooms] >= config[:indexing_rules][:bedrooms]
        @events_queue.push(event_klass.new(@id, { :document => doc, :index => index }))
        current += 1
        @fetched += 1
      end
    end

    # XXX naive loop
    @existing_ids.each do |doc_id|
      next if seen_ids.include?(doc_id)
      @events_queue.push(DeleteEvent.new(@id, index, doc_id))
    end

    @events_queue.push(FinishedEvent.new(@id))
    @status = FINISHED
  end
end

class StreamSync
  attr_reader :id, :status

  def initialize(manager, data_source, event_callback, configuration)
    @manager = manager
    @data_source = data_source
    @id = SecureRandom.uuid
    @events_queue = Queue.new
    @status = INITIALIZED
    @event_callback = event_callback
    @configuration = configuration
    @streamer = nil
    @index = @configuration.read[:indexing_rules][:index_target]
  end

  def to_s
    "StreamJob #{@id[0..7]}/#{@status}"
  end

  def close
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
    @status = WORKING

    # config = @configuration.read
    Thread.abort_on_exception = true
    @streamer = Thread.new {
      begin
        puts('Change stream started')
        stream = @data_source.change_stream
        loop do
          change = stream.next
          # XXX need to implement changes deletes,
          # for now it's just addition
          doc = change[:fullDocument]
          doc = doc.transform_keys(&:to_sym)
          @event_callback.call(ChangedEvent.new(@id, { :document => doc, :index => @index }))

          puts(to_s)
          # @event_callback.call(ChangedEvent.new(@id, change))
        end

        @events_queue.push(FinishedEvent.new(@id))
        @status = FINISHED
      rescue StandardError => e
        print_exception(e)
      end
    }
  end
end
