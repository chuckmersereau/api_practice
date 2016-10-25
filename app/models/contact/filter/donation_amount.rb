class Contact::Filter::DonationAmount < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations])
      contacts = contacts.where(donations: { amount: filters[:donation_amount] })
      contacts
    end

    def title
      _('Exact Gift Amount')
    end

    def parent
      _('Gift Details')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      account_list.donations.where.not(amount: nil).pluck(:amount).uniq.sort.collect { |amount| { name: amount, id: amount } }
    end

    private

    def valid_filters?(filters)
      super && filters[:donation_amount].is_a?(Array)
    end
  end
end
