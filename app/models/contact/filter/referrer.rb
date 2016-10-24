class Contact::Filter::Referrer < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filters = Array(filters[:referrer])
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

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' },
       { name: _('-- Has referrer --'), id: 'any' }] +
        account_list.contacts.with_referrals.order('name').collect { |c| { name: c.name, id: c.id } }
    end
  end
end
