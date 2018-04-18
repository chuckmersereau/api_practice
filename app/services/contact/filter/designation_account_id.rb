class Contact::Filter::DesignationAccountId < Contact::Filter::Base
  def execute_query(contacts, filters)
    contact_ids = contacts.includes(donor_accounts: :donations)
                          .where(donations: { designation_account_id: filters[:designation_account_id] })
                          .where.not(donations: { id: nil })
                          .pluck(:id)
    contacts.where(id: contact_ids)
  end

  def title
    _('Designation Acccount')
  end

  def parent
    _('Gift Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_lists.collect(&:designation_accounts).flatten.compact.map do |designation_account|
      { id: designation_account.id, name: DesignationAccountSerializer.new(designation_account).display_name }
    end
  end

  def valid_filters?(filters)
    filters[name].present? && !filters[name].is_a?(Hash)
  end
end
