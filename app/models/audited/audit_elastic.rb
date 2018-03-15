require 'elasticsearch/persistence/model'

module Audited
  class AuditElastic
    include Elasticsearch::Persistence::Model

    INDEX_BASE = ['mpdx', 'uuid', Rails.env].join('-').freeze

    index_name [INDEX_BASE, Date.today.to_s.tr('-', '.')].join('-')

    attribute :auditable_id, String
    attribute :auditable_type, String
    attribute :associated_id, String
    attribute :associated_type, String
    attribute :user_id, String
    attribute :user_type, String
    attribute :action, String
    attribute :audited_changes, String
    attribute :comment, String
    attribute :remote_address, String
    attribute :request_uuid, String
    attribute :created_at, DateTime

    def parsed_audited_changes
      JSON.parse audited_changes.gsub('=>', ':').gsub('nil', 'null')
    end

    def undo(comment = nil)
      object = audited_object
      object.audit_comment = comment

      if action == 'create'
        # destroys a newly created record
        object.destroy!
      elsif action == 'destroy'
        # creates a new record with the destroyed record attributes
        object.save
      else
        # changes back attributes
        parsed_audited_changes.each { |attrs, changes| object[attrs] = changes[0] }
        object.save
      end
    end

    def audited_object
      model = auditable_type.constantize
      return model.find(auditable_id) unless action == 'destroy'
      auditable_type.constantize.new(parsed_audited_changes)
    end

    def user
      return user_type unless user_id
      user_type.constantize.find(user_id)
    end
  end
end
