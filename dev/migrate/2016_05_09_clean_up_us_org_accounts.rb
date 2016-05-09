class USOrgAccountCleaner
  def clean_up_us_org_accounts
    # there are 1297 US OrganizationAccounts that have <12 characters remote_ids.
    # I'm pretty sure those are employee ids and the rest are the Relay guid of the user
    # of those 1297, 41 have more than one relay account on the user

    # of those 41, 34 are two relay accounts with the same guid that I believe we can delete one
    # the remaining 7 are couples who have added both spouses to their one user

    # currently the Siebel class finds relay guids by @org_account.user.relay_accounts.first.remote_id
    # if we got all of the organization remote_ids to be the relay guid we could remove the
    # Siebel <-> RelayAccount coupling
    who_needs_fixing = Person::OrganizationAccount.where(organization_id: Organization.cru_usa.id).where('CHAR_LENGTH(remote_id) < 12')
    who_needs_fixing.find_each do |org_account|
      relay_accounts = org_account.user.relay_accounts
      if relay_accounts.none?
        # we don't need to keep US organization accounts if the relay account doesn't exist
        org_account.destroy
        next
      end
      relay_guid = relay_accounts.first.remote_id
      if relay_accounts.count > 1
        owner_relay = relay_accounts.find { |relay| relay.employee_id == org_account.remote_id }
        relay_guid = owner_relay.remote_id if owner_relay
      end
      org_account.update(remote_id: relay_guid)
    end
  end
end
