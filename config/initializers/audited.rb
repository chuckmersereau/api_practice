# money patch Audit class to save to Elasticsearch instead of the db
require 'elasticsearch/persistence/model'
require 'audited'

Elasticsearch::Persistence.client = if Rails.env.test?
                                      Elasticsearch::Client.new host: 'example.com'
                                    else
                                      Elasticsearch::Client.new host: ENV['ELASTICSEARCH_URL'],
                                                                port: ENV['ELASTICSEARCH_PORT']
                                    end

module Audited
  class Audit
    def self.exists?
      true
    end
  end

  # monkey-patch gem module
  module Auditor
    module AuditedInstanceMethods
      def write_audit(attrs)
        # clear comment if it was added
        self.audit_comment = nil

        return unless system_auditing_enabled && auditing_enabled

        attrs[:audited_changes] = attrs[:audited_changes].to_s
        attrs[:created_at] = DateTime.now
        set_request_uuid(attrs)
        set_remote_address(attrs)
        set_audit_user(attrs)
        set_auditable(attrs)
        set_associated(attrs)

        run_callbacks(:audit) { AuditChangeWorker.perform_async(attrs) }
      end

      def audits
        Audited::AuditSearch.search_by(auditable_type: self.class.to_s, auditable_id: id)
      end

      private

      def system_auditing_enabled
        ENV['ELASTICSEARCH_URL'].present? && !Rails.env.test?
      end

      def set_request_uuid(attrs)
        attrs[:request_uuid] ||= ::Audited.store[:current_request_uuid]
      end

      def set_remote_address(attrs)
        attrs[:remote_address] ||= ::Audited.store[:current_remote_address]
      end

      def set_audit_user(attrs)
        return if attrs[:user_id]
        user = ::Audited.store[:audited_user] || ::Audited.store[:current_user]&.call
        set_model_field(attrs, :user, user)
      end

      def set_auditable(attrs)
        set_model_field(attrs, :auditable, self)
      end

      def set_associated(attrs)
        return if audit_associated_with.nil?
        set_model_field(attrs, :associated, send(audit_associated_with))
      end

      def set_model_field(attrs, field, object)
        return unless object
        attrs["#{field}_id".to_sym] = object.try(:id)
        attrs["#{field}_type".to_sym] = object.class.to_s
      end
    end
  end
end
