require 'elasticsearch/persistence/model'

module Audited
  class AuditSearch < Audited::AuditElastic
    include Elasticsearch::Persistence::Model

    index_name ['mpdx', Rails.env, '*'].join('-')

    def self.dump(klass)
      search_by(
        bool: {
          must: [
            { match: { auditable_type: klass } }
          ]
        }
      )
    end

    # can accept a complicated query value like:
    # {
    #   bool: {
    #     must: [
    #       { match: { auditable_type: klass } },
    #       { match: { auditable_id: 1 } }
    #     ]
    #   }
    # }
    #
    # or something simple like:
    # { auditable_type: klass, auditable_id: 1 }
    # which will be converted to the verbose form
    def self.search_by(query)
      query = expand_hash(query) unless query.any? { |_, value| value.is_a? Hash }

      find_each(type: nil,
                query: query,
                sort: ['_doc'],
                size: 100)
    end

    def self.expand_hash(hash)
      {
        bool: {
          must: hash.map { |k, v| { match: { k => v } } }
        }
      }
    end
  end
end
