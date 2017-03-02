class Contact::Filter::Timezone < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('contacts.timezone' => filters[:timezone])
  end

  def title
    _('Timezone')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_lists.map(&:timezones).flatten.uniq.select(&:present?).map { |timezone| { name: timezone, id: timezone } }
  end
end
