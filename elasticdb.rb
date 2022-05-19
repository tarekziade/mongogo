# frozen_string_literal: true

# This class is in charge of sending documents to Elastic
# And also in charge of creating an index mapping
class ElasticDB

  def push(doc)
    # XXX we can use the Keep-Alive thing to continuously push I guess
    puts("Write in ES #{doc['listing_url']}")
  end

end

# This class can be used by a sync Job to read some configuration info
# Things like auth tokens, indexing rules, etc.
class ElasticConfig
  def read
    {
      auth_token: 'secret',
      indexing_rules: {
        bedrooms: 2
      }
    }
  end
end
