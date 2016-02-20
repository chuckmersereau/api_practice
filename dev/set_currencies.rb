# These methods are useful in setting the initial currency values
# as we prepare to deploy the multi-currency feature.

def default_pledge_currencies!
  sql = <<-EOS
    update contacts
    set pledge_currency = (
       select currency
       from donations
       where donations.donor_account_id = donor_accounts.id
       limit 1
    )
    from contact_donor_accounts, donor_accounts
    where
      contact_donor_accounts.contact_id = contacts.id and
      donor_accounts.id = contact_donor_accounts.donor_account_id and
      contacts.pledge_currency is null;
  EOS
  ActiveRecord::Base.connection.execute(sql)
end

def default_account_list_currencies!
  org_currencies = Hash[Organization.pluck(:id, :default_currency_code)]
  AccountList.where.not("settings like '%currency%'").find_each do |account_list|
    default_account_list_currency!(account_list, org_currencies)
  end
end

def default_account_list_currency!(account_list, org_currencies)
  org_ids = account_list.organization_accounts.map(&:organization_id)
  account_org_currencies = org_ids.map { |id| org_currencies[id] }.compact.uniq

  if account_org_currencies.size == 1
    currency = account_org_currencies.first
    account_list.update(currency: currency)
    puts "Set currency for account #{account_list.id} to #{currency} by org"
  else
    default_currencies_by_pledges!(account_list)
  end
end

def default_currencies_by_pledges!(account_list)
  currency_counts = account_list.contacts.where
                    .not(pledge_currency: nil).group(:pledge_currency).count
  if currency_counts.empty?
    puts "No currency info for account #{account_list.id}"
    return
  end
  currency = currency_counts.max_by { |_k, v| v }.first
  if currency.blank?
    puts "No currency info for account #{account_list.id}"
  else
    account_list.update(currency: currency)
    puts "Set currency for account #{account_list.id} to #{currency} by pledges"
  end
end
