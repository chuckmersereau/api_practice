class Contact::Filter::Likely < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filters[:likely] << nil if Array(filters[:likely]).delete('none')
      contacts.where(likely_to_give: filters[:likely])
    end

    def title
      _('Likely To Give')
    end

    def parent
      _('Contact Details')
    end

    def type
      'multiselect'
    end

    def custom_options(_account_list)
      [{ name: _('-- None --'), id: 'none' }] + contact_instance.assignable_likely_to_gives.map { |s| { name: _(s), id: s } }
    end
  end
end
