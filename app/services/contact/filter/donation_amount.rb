
class Contact::Filter::DonationAmount < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations])
    contacts = contacts.where(donations: { amount: filters[:donation_amount].split(',').map(&:strip) })
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

  def custom_options
    account_lists.collect { |account_list| account_list.donations.where.not(amount: nil).pluck(:amount) }
                 .flatten
                 .uniq
                 .sort
                 .collect { |amount| { name: amount, id: amount } }
  end
end
