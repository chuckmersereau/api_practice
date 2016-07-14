class AddAccountsToDonations
  def add_accounts_to_donations
    donations_without_designation_accounts.each do |donation|
      next unless donation.donor_account.contacts.count == 1
      org_accounts = org_accounts(contacts.first.account_list)
      next unless org_accounts.count == 1
      designation_account = designation_account(org_accounts.first)
      next unless designation_account
      donation.update_attributes(designation_account_id: designation_account.id)
    end
  end

  private

  def donations_without_designation_accounts
    Donation.where(designation_account_id: nil)
  end

  def org_accounts(account_list)
    account_list.organization_accounts
        .map{ |oa| account_list.creator_id == oa.person_id }
  end

  def designation_account(org_account)
    DesignationAccount.find_by(
        organization_id: org_account.organization_id,
        active: true,
        designation_number: org_account.id.to_s)
  end
end
