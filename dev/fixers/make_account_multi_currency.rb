# Provides a quick and dirty way to turn an account list into a multi-currency
# account for test purposes. Note that once the donation import is run again for
# this account the currencies will revert back to what they were from
# DataServer/Siebel. You can get around that by disconnecting the account from
# say ToonTown assumming no other users also have a connection to it.
def make_account_multi_currency(account_list)
  account_list.contacts.find_each do |contact|
    puts contact.id
    if contact.id % 3 == 0
      contact.update(pledge_currency: 'GBP')
      contact.donations.update_all(currency: 'GBP', tendered_currency: 'GBP')
    elsif contact.id % 5 == 0
      contact.update(pledge_currency: 'EUR')
      contact.donations.update_all(currency: 'EUR', tendered_currency: 'EUR')
    end
  end
end
