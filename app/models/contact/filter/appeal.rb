class Contact::Filter::Appeal < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts = contacts.where(no_appeals: true) if filters[:appeal].delete('no_appeals')
      contacts = contacts.where(appeals: { uuid: filters[:appeal] }).includes(:appeals).uniq if filters[:appeal].present?
      contacts
    end

    def title
      _('Appeal')
    end

    def type
      'multiselect'
    end

    def custom_options(account_lists)
      [{ name: '-- Do not ask --', id: 'no_appeals' }] + account_lists.map(&:appeals).flatten.uniq.map { |a| { name: a.name, id: a.id } }
    end
  end
end
