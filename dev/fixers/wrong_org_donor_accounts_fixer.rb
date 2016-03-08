# There was a bug in the Tnt import that would make it so when someone
# imported from Tnt and they had multiple organizations, MPDX could
# incorrectly associate some of their donor accounts with the wrong
# organization.
# Because of the way the contact merge logic works (just considering
# donor account numbers not organizations), when people merged contacts
# together, donations would disappear.
#
# These functions allow you to correct a user's account by going through
# their donor accounts and setting those that were incorrectly labeled.
#
# The first two methods donor_accounts_counts_by_org and empty_donor_accounts
# allow you to look up what donor accounts an account list has to diagnose which
# organization was incorrectly assigned to some of their donor accounts.
#
# Then to correct the problem, call fix_all_donor_accounts with the account
# list, the org that was wrongly set and the correct org.
#
# For instance, if someone is from Canada and they imported from TntMPD but a
# lot of their donor accounts got marked as as Cru USA incorrectly, then you
# would call the method like this:
#
# ptc = Organization.find_by(name: 'Power to Change - Canada')
# fix_all_donor_accounts(account_list, Organization.cru_usa, ptc)

# Gives an overview of the organizations that are in an account's donors to help
# diagnose which organization might have been wrongly added by the Tnt import.
def donor_accounts_counts_by_org(account_list)
  account_list.donor_accounts.group(:organization_id).count
end

# Shows the empty donor accounts for an account list, helpful for diagnosing
# which organization was incorrectly set onto their account lists.
def empty_donor_accounts(account_list)
  account_list.donor_accounts.select do |da|
    da.donations.count == 0
  end
end

# Main fixer method to use on an account list
def fix_all_donor_accounts(account_list, wrong_org, right_org)
  account_list.contacts.each do |contact|
    fix_donor_accounts(contact, wrong_org, right_org)
  end
  nil
end

##############################################
# Helper methods for fix_all_donor_accounts above
##############################################

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
