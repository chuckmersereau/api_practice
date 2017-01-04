class Contact::Filter::Tags < Contact::Filter::Base
  def execute_query(contacts, filters)
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
