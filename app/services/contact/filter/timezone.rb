class Contact::Filter::Timezone < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('contacts.timezone' => timezone_filters(filters))
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

  private

  def timezone_filters(filters)
    @timezone_filters ||= filters[:timezone].split(',').map(&:strip)
  end
end
