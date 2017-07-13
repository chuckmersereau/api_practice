# This class handles the addition of merge fields to Mail Chimp. Merge fields are basically custom fields
# on the MailChimp side that we use to store statuses and tags that a contact has.
class MailChimp::Exporter
  class MergeFieldAdder
    MAILCHIMP_MAX_ALLOWED_MERGE_FIELDS = 20

    attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

    def initialize(mail_chimp_account, gibbon_wrapper, list_id)
      @mail_chimp_account = mail_chimp_account
      @gibbon_wrapper = gibbon_wrapper
      @list_id = list_id
    end

    def add_merge_field(field_name)
      @field_name = field_name

      return if should_not_create_merge_field?

      create_merge_field
    rescue Gibbon::MailChimpError => error
      raise unless error.detail =~ /Merge Field .* already exists/
    end

    private

    def should_not_create_merge_field?
      merge_fields.find { |merge_field| merge_field['tag'] == @field_name } ||
        merge_fields.size == MAILCHIMP_MAX_ALLOWED_MERGE_FIELDS
    end

    def create_merge_field
      gibbon_list.merge_fields.create(
        body: {
          tag: @field_name, name: _(cleaned_field_name), type: 'text'
        }
      )
    end

    def cleaned_field_name
      @field_name.downcase.tr('-', '').capitalize
    end

    def merge_fields
      @merge_fields ||= gibbon_list.merge_fields.retrieve['merge_fields']
    end

    def gibbon_list
      gibbon_wrapper.gibbon_list_object(list_id)
    end
  end
end
