class AccountList::FromDesignationsFinder
  def initialize(numbers, organization)
    @numbers = numbers
    @organization = organization
  end

  def account_list
    account_list_id = account_list_ids_with_designations.min
    account_list_id.present? ? AccountList.find(account_list_id) : nil
  end

  private

  attr_reader :numbers, :organization

  def account_list_ids_with_designations
    # By using a count query we can filter for only those account lists that
    # have all of the designation account ids we are looking for.
    AccountList.joins(:account_list_entries)
      .where(account_list_entries: { designation_account_id: designation_ids })
      .group(:account_list_id).having('count(*) = ?', designation_ids.count)
      .count.keys
  end

  def designation_ids
    @designation_ids ||=
      DesignationAccount.where(designation_number: numbers)
      .where(organization_id: organization.id).pluck(:id).sort
  end
end
