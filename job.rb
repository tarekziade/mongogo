# frozen_string_literal: true

# Handles a Sync Job
class SyncJob
  attr_reader :id, :status, :documents_queue

  def initialize(job_id, data_source, status_callback, configuration)
    # backend to read config, write
    @data_source = data_source
    @id = job_id
    @documents_queue = Queue.new
    @status = 'initialized'
    @status_callback = status_callback
    @configuration = configuration
  end

  def run
    @status = 'working'
    puts('Grabbing configuration')
    config = @configuration.read

    @data_source.documents.each do |doc|
      # filter!
      if !doc[:bedrooms].nil? && doc[:bedrooms] >= config[:indexing_rules][:bedrooms]
        @documents_queue.push(doc)
        @status_callback.call(self)
      end
    end

    @documents_queue.push('FINISHED')
    @status = 'finished'
    @status_callback.call(self)
  end
end
