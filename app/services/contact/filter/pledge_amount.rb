class Contact::Filter::PledgeAmount < Contact::Filter::Base
  def execute_query(contacts, filters)
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

  def custom_options
    account_lists.collect { |account_list| account_list.contacts.pluck(:pledge_amount).uniq.compact.sort }
                 .flatten
                 .uniq
                 .collect { |amount| { name: amount, id: amount } }
  end
end