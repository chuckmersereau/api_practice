class Contact::Filter::Referrer < Contact::Filter::Base
  def execute_query(contacts, filters)
    filters = filters[:referrer].split(',').map(&:strip)
    filters << nil if filters.delete('none')
    contacts = contacts.includes(:contact_referrals_to_me).where.not(contact_referrals: { referred_by_id: nil }) if filters.delete('any')
    contacts = contacts.includes(:contact_referrals_to_me).where(contact_referrals: { referred_by_id: filters }) if filters.present?
    contacts
  end

  def title
    _('Referrer')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('-- None --'), id: 'none' },
     { name: _('-- Has referrer --'), id: 'any' }] +
      account_lists.map { |account_list| account_list.contacts.with_referrals.order('name') }
                   .flatten
                   .uniq
                   .collect { |c| { name: c.name, id: c.uuid } }
  end
end
