# frozen_string_literal: true

# Handles a Sync Job
class SyncJob
  attr_reader :id, :status

  def initialize(job_id, data_source, status_callback, configuration)
    # backend to read config, write
    @data_source = data_source
    @id = job_id
    @status = { status: 'initialized', job: self, documents: [] }
    @status_callback = status_callback
    @configuration = configuration
  end

  def run
    @status[:status] = 'started'
    puts('Grabbing configuration')
    config = @configuration.read

    @data_source.documents.each do |doc|
      # filter!
      if doc[:price] < config[:indexing_rules][:max_price]
        @status[:documents].push(doc)
        @status_callback.call(@status)
      end
    end

    @status[:status] = 'finished'
    @status_callback.call(@status)
  end
end
