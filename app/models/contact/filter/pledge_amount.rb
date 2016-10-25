class Contact::Filter::PledgeAmount < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      return unless filters[:pledge_amount].is_a?(Array)
      contacts.where(pledge_amount: filters[:pledge_amount])
    end

    def title
      _('Commitment Amount')
    end

    def parent
      _('Commitment Details')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      account_list.contacts.pluck(:pledge_amount).uniq.compact.sort.collect { |amount| { name: amount, id: amount } }
    end
  end
end
