# frozen_string_literal: true
require_relative 'events'

# Sync events
class AddEvent
  attr_reader :job_id, :data

  def initialize(job_id, data)
    @job_id = job_id
    @data = data
  end
end

class FinishedEvent
  attr_reader :job_id

  def initialize(job_id)
    @job_id = job_id
  end
end

class ChangedEvent
  attr_reader :job_id, :data

  def initialize(job_id, data)
    @job_id = job_id
    @data = data
  end
end
