require 'elasticsearch/persistence/model'

module Audited
  class AuditElastic
    include Elasticsearch::Persistence::Model

    index_name ['mpdx', 'uuid', Rails.env, Date.today.to_s.tr('-', '.')].join('-')

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

    def undo
      model = auditable_type.constantize
      if action == 'create'
        # destroys a newly created record
        model.find(auditable_id).destroy!
      elsif action == 'destroy'
        # creates a new record with the destroyed record attributes
        model.create(parsed_audited_changes)
      else
        # changes back attributes
        audited_object = model.find(auditable_id)
        parsed_audited_changes.each do |k, v|
          audited_object[k] = v[0]
        end
        audited_object.save
      end
    end

    def user
      return user_type unless user_id
      user_type.constantize.find(user_id)
    end
  end
end
