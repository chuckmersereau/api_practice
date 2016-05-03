require 'spec_helper'

describe Contact::DonationsEagerLoader, '#contacts_with_donations' do
  let(:account_list) { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact) do
    create(:contact, account_list: account_list)
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  context '#contacts_with_donations' do
    it 'returns contacts with loaded_donations set' do
      donation = create(:donation, donor_account: donor_account,
                                   designation_account: designation_account)

      contacts = Contact::DonationsEagerLoader.new(account_list: account_list)
                                              .contacts_with_donations

      expect(contacts).to eq [contact]
      expect(contacts.first.loaded_donations).to eq [donation]
    end

    it 'excludes contacts that do not match contact scoper' do
      loader = Contact::DonationsEagerLoader
               .new(account_list: account_list,
                    contacts_scoper: -> (contacts) { contacts.where(id: -1) })

      expect(loader.contacts_with_donations).to be_empty
    end

    it 'excludes donations that do not match donation scoper' do
      create(:donation, donation_date: Date.new(2015, 1, 1),
                        donor_account: donor_account,
                        designation_account: designation_account)
      donations_scoper = lambda do |donations|
        donations.where.not(donation_date: Date.new(2015, 1, 1))
      end
      contacts = Contact::DonationsEagerLoader
                 .new(account_list: account_list, donations_scoper: donations_scoper)
                 .contacts_with_donations

      expect(contacts.first.loaded_donations).to be_empty
    end

    it 'excludes donations for designation not in account list' do
      create(:donation, donor_account: donor_account,
                        designation_account: create(:designation_account))

      contacts = Contact::DonationsEagerLoader.new(account_list: account_list)
                                              .contacts_with_donations

      expect(contacts).to eq [contact]
      expect(contacts.first.loaded_donations).to be_empty
    end
  end

  context '#donations_and_contacts' do
    it 'returns donations and contacts with donations loaded_contact set' do
      donation = create(:donation, donor_account: donor_account,
                                   designation_account: designation_account)

      donations, contacts = Contact::DonationsEagerLoader
                            .new(account_list: account_list)
                            .donations_and_contacts

      expect(contacts).to eq [contact]
      expect(donations).to eq [donation]
      expect(donations.first.loaded_contact).to eq contact
    end
  end
end
