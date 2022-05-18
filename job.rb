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
    # XXX we can get some info from @configuration on what to do
    @data_source.documents.each do |doc|
      @status[:documents].push(doc)
      @status_callback.call(@status)
    end
    @status[:status] = 'finished'
    @status_callback.call(@status)
  end
end
