class Contact::Filter::Notes < Contact::Filter::Base
  def execute_query(contacts, filters)
    search_term = filters[:notes][:wildcard_note_search].to_s.downcase
    return contacts if search_term.blank?
    contacts.where('contacts.notes ilike ?', "%#{search_term}%")
  end

  def title
    _('Notes')
  end

  def parent
    _('Search Notes')
  end

  def type
    'text'
  end

  def custom_options
    [{ name: _('Search note contents'), id: 'wildcard_note_search' }]
  end

  def valid_filters?(filters)
    filters[:notes].present? && filters[:notes][:wildcard_note_search].to_s.present?
  end
end
