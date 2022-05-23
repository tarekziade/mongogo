# frozen_string_literal: true
require_relative 'events'

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB
  def initialize
    @indices = Concurrent::Hash.new
  end

  def purge
    puts('This is where we can bake batch queries maybe')
  end

  def push(event)
    case event
    when AddEvent
      document = event.data[:document]
      index = event.data[:index]
      @indices[index] = [] unless @indices.include?(:index)
      @indices[index].push(document)
    when FinishedEvent
      purge
    end
  end

end

# This class can be used by a sync Job to read some configuration info
# Things like auth tokens, indexing rules, etc.
class ElasticConfig
  def read
    {
      auth_token: 'secret',
      indexing_rules: {
        index_target: 'airbnb',
        bedrooms: 2
      }
    }
  end
end
