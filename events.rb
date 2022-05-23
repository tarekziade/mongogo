# frozen_string_literal: true
require_relative 'events'

# Sync events
class AddEvent
  def initialize(job_id, data)
    @job_id = job_id
    @data = data
  end
end

class FinishedEvent
  def initialize(job_id)
    @job_id = job_id
  end
end
