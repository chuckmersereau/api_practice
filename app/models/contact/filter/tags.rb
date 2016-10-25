class Contact::Filter::Tags < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      return unless valid_filters?(filters)
      contacts = contacts.tagged_with(filters[:tags].split(',').flatten, any: filters[:any_tags] == 'true') if filters[:tags].present?
      contacts = contacts.tagged_with(filters[:exclude_tags].split(',').flatten, exclude: true) if filters[:exclude_tags].present?
      contacts
    end

    private

    def valid_filters?(filters)
      super || filters[:exclude_tags].present?
    end
  end
end
