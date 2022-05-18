# frozen_string_literal: true

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB
  def write(documents)
    documents.each do |document|
      puts("Write in ES #{document}")
    end
  end
end

# This class can be used by a sync Job to read some configuration info
# Things like auth tokens, indexing rules, etc.
class ElasticConfig
  def read
    {}
  end
end
