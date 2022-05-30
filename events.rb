# frozen_string_literal: true

# Sync events
class AddEvent
  attr_reader :job_id, :data

  def initialize(job_id, data)
    @job_id = job_id
    @data = data
  end
end

class ModifyEvent
  attr_reader :job_id, :data

  def initialize(job_id, data)
    @job_id = job_id
    @data = data
  end
end

class JobCreatedEvent
  attr_reader :job_id, :index

  def initialize(job_id, index)
    @job_id = job_id
    @data = { :index => index }
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

class DeleteEvent
  attr_reader :job_id, :data

  def initialize(job_id, index, doc_id)
    @job_id = job_id
    @data = { :index => index, :document => { :_id => doc_id } }
  end
end
