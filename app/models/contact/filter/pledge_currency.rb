class Contact::Filter::PledgeCurrency < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, user)
      default_currencies = user.account_lists.collect(&:default_currency)
      if (filters[:pledge_currency] & default_currencies).present?
        contacts.where(pledge_currency: [filters[:pledge_currency], '', nil])
      else
        contacts.where(pledge_currency: filters[:pledge_currency])
      end
    end

    def title
      _('Commitment Currency')
    end

    def parent
      _('Commitment Details')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      account_list.currencies.select(&:present?).map { |a| { name: a, id: a } }
    end
  end
end
