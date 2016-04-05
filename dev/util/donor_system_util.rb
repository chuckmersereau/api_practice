def data_server_profiles(user)
  data_server = DataServer.new(org_account(user))
  data_server.send(:profiles)
end

def siebel_profiles(user)
  siebel = Siebel.new(org_account(user))
  siebel.send(:profiles)
end

def org_account(user)
  org_accounts = user.organization_accounts
  if org_accounts.count > 1
    puts "User #{user} has #{org_accounts.count} org accounts"
  end
  org_accounts.first
end

def donors_response(org_account, profile)
  d = DataServer.new(org_account)
  org = org_account.organization
  params = d.send(:get_params,
                  org.addresses_params,
                  profile: profile.code.to_s,
                  datefrom: org.minimum_gift_date.to_s,
                  personid: org_account.remote_id)
  d.send(:get_response, org.addresses_url, params)
end

def desig_profile(profile, oa)
  Retryable.retryable do
    if profile.id
      oa.organization.designation_profiles.where(user_id: oa.person_id, code: profile.id)
        .first_or_create(name: profile.name)
    else
      oa.organization.designation_profiles.where(user_id: oa.person_id, code: nil)
        .first_or_create(name: profile.name)
    end
  end
end

def fix_donation_totals(account_list)
  account_list = account_list.id unless account_list.blank? || account_list.is_a?(Integer)
  sql = '
  UPDATE contacts
  SET total_donations = correct_totals.total
  FROM (
    SELECT contacts.id contact_id, SUM(donations.amount) total
    FROM contacts, contact_donor_accounts, account_list_entries, donations
    WHERE contacts.id = contact_donor_accounts.contact_id
    AND donations.donor_account_id = contact_donor_accounts.donor_account_id
    AND contacts.account_list_id = account_list_entries.account_list_id ' +
        (account_list ? "AND account_list_entries.account_list_id = #{account_list}" : '') +
        ' AND donations.designation_account_id = account_list_entries.designation_account_id
    GROUP BY contacts.id
    ) correct_totals
  WHERE correct_totals.contact_id = contacts.id
  '
  Donation.connection.execute(sql)
end
