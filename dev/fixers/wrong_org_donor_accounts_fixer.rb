def donor_accounts_counts_by_org(account_list)
  account_list.donor_accounts.group(:organization_id).count
end

def empty_donor_accounts(account_list)
  account_list.donor_accounts.select do |da|
    da.donations.count == 0
  end
end

def fix_all_donor_accounts(account_list, wrong_org, right_org)
  account_list.contacts.each do |contact|
    fix_donor_accounts(contact, wrong_org, right_org)
  end
  nil
end

def fix_donor_accounts(contact, _wrong_org, right_org)
  contact.donor_accounts.each do |da|
    next if da.organization == right_org || da.donations.count > 0
    remove_donor_account(contact, da)
    add_right_donor_account(contact, da.account_number, right_org)
  end
end

def remove_donor_account(contact, donor_account)
  contact.contact_donor_accounts.where(donor_account: donor_account).each do |_cda|
    puts "Removing wrong org donor #{donor_account.id} from contact #{contact.id}"
  end
  puts "Deleting wrong org donor account #{donor_account.inspect}"
  donor_account.destroy
end

def add_right_donor_account(contact, account_number, right_org)
  right_da = right_org.donor_accounts.find_by(account_number: account_number)
  if right_da.nil?
    puts "Could not find right org donor for ##{account_number} for conact #{contact.id}"
  elsif already_has_donor_account?(contact, account_number, right_org)
    puts "Contact #{contact.id} already has right org donor #{right_da.id}"
  else
    puts "Adding right org donor #{right_da.id} to contact #{contact.id}"
    contact.donor_accounts << right_da
  end
end

def already_has_donor_account?(contact, account_number, right_org)
  numbers = contact.donor_accounts.where(organization: right_org).pluck(:account_number)
  numbers.include?(account_number)
end
