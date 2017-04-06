class Contact::Filter::Referrer < Contact::Filter::Base
  def execute_query(contacts, filters)
    filters = parse_list(filters[:referrer])
    contacts = contacts.joins(:contact_referrals_to_me).where.not(contact_referrals: { referred_by_id: nil }) if filters.delete('any')
    contacts = contacts.joins('LEFT OUTER JOIN "contact_referrals" ON "contact_referrals"."referred_to_id" = "contacts"."id"')
                       .where(contact_referrals: { referred_by_id: contact_referrer_ids(filters) }) if filters.present?
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

  private

  def contact_referrer_ids(filters)
    contact_referrer_ids = Contact.where(uuid: filters - ['none']).ids
    contact_referrer_ids << nil if filters.include?('none')
    contact_referrer_ids
  end
end
