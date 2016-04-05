class AccountList::FromDesignationsFinder
  def initialize(numbers, organization_id)
    @numbers = numbers
    @organization_id = organization_id
  end

  def account_list
    AccountList.where(id: account_list_ids_with_designations)
               .select(&method(:no_other_designations_for_org?)).min_by(&:id)
  end

  private

  # We want to filter out account lists whose designations for a particular
  # organization are greater than the designation numbers specified for a
  # specific user so that that user isn't allowed to view the higher-level
  # account lists for an organization unless they are authorized to view all the
  # designations for that account. But the comparision should be done on a
  # per-organization basis so that we can match account lists that have
  # designations from multiple organizations merged into them (e.g. for staff
  # with multiple currencies and accounts in different countries)
  def no_other_designations_for_org?(account_list)
    account_list.designation_accounts.where(organization_id: @organization_id)
                .pluck(:id).sort == designation_ids
  end

  # Returns the account lists that contain all of the designations
  # This could include both personal accounts as well as higher-level ministry
  # accounts that e.g. contain all the designations for a particular ministry.
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
      DesignationAccount.where(designation_number: @numbers)
                        .where(organization_id: @organization_id).pluck(:id).sort
  end
end
