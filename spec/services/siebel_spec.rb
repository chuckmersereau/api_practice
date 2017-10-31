# rubocop:disable Metrics/LineLength
require 'rails_helper'

describe Siebel do
  let(:wsapi) { 'https://wsapi.ccci.org/wsapi/rest' }
  let(:org) { create(:organization) }
  let(:person) { create(:person) }
  let(:org_account) { build(:organization_account, person: person, organization: org) }
  let(:account_list) { create(:account_list) }
  let(:designation_profile) { create(:designation_profile, user: person.to_user, organization: org, account_list: account_list) }
  let!(:siebel) { Siebel.new(org_account) }
  let(:designation_account_one) { build(:designation_account, staff_account_id: 1, organization: org) }
  let(:designation_account_two) { build(:designation_account, staff_account_id: 2, organization: org) }
  let(:donor_account) { create(:donor_account, organization: org) }
  let(:contact) { create(:contact) }
  let(:siebel_donor) do
    SiebelDonations::Donor.new(Oj.load('{ "id": "602506447", "accountName": "Hillside Evangelical Free Church", "contacts": [ { "updatedAt":"' + 1.day.ago.to_s(:db) + '","id": "1-2XH-663", "primary": true, "firstName": "Friend", "lastName": "of the Ministry", "sex": "Unspecified", "phoneNumbers": [ { "updatedAt":"' + 1.day.ago.to_s(:db) + '","id": "1-CI7-4832", "type": "Work", "primary": true, "phone": "408/269-4782" } ] } ], "addresses": [ { "updatedAt":"' + 1.day.ago.to_s(:db) + '","id": "1-HS7-779", "type": "Mailing", "primary": true, "seasonal": false, "address1": "545 Hillsdale Ave", "city": "San Jose", "state": "CA", "zip": "95136-1202" } ], "type": "Business" }'))
  end

  before do
    account_list.users << person.to_user

    stub_smarty_streets
  end

  context '#import_profiles' do
    let!(:relay) { create(:relay_account, person: person) }

    it 'imports profiles for a relay guid' do
      stub_request(:get, "#{wsapi}/profiles?response_timeout=60000&ssoGuid=#{org_account.remote_id}")
        .to_return(body: '[ { "name": "Staff Account (0559826)", "designations": [ { "number": "0559826", "description": "Joshua and Amanda Starcher (0559826)", "staffAccountId": "000559826" } ] }]')

      expect(siebel).to receive(:find_or_create_designation_account)

      expect do
        siebel.import_profiles
      end.to change { DesignationProfile.count }.by(1)
    end
  end

  context '#import_profile_balance' do
    it 'sets the profile balance to the sum of designation account balances in this profile' do
      stub_request(:get, "#{wsapi}/staffAccount/balances?employee_ids=1&response_timeout=60000")
        .to_return(body: '{ "1": { "primary": 1 }}')
      stub_request(:get, "#{wsapi}/staffAccount/balances?employee_ids=2&response_timeout=60000")
        .to_return(body: '{ "2": { "primary": 2 }}')

      designation_profile.designation_accounts << designation_account_one
      designation_profile.designation_accounts << designation_account_two

      siebel.import_profile_balance(designation_profile)

      expect(designation_profile.balance).to eq(3)
    end

    it 'updates the balance of a designation account on that profile' do
      stub_request(:get, "#{wsapi}/staffAccount/balances?employee_ids=1&response_timeout=60000")
        .to_return(body: '{ "1": { "primary": 1 }}')

      designation_profile.designation_accounts << designation_account_one

      siebel.import_profile_balance(designation_profile)

      expect(designation_account_one.balance).to eq(1)
    end

    it 'sets inactive designation accounts to a zero balance thus excluding their amount from the profile total' do
      stub_request(:get, "#{wsapi}/staffAccount/balances?employee_ids=1&response_timeout=60000")
        .to_return(body: '{ "1": { "primary": 1 }}')
      stub_request(:get, "#{wsapi}/staffAccount/balances?employee_ids=2&response_timeout=60000")
        .to_return(body: '{ "2": { "primary": 2 }}')

      designation_profile.designation_accounts << designation_account_one
      designation_profile.designation_accounts << designation_account_two
      designation_account_one.update(active: false)

      siebel.import_profile_balance(designation_profile)
      expect(designation_profile.balance).to eq(2)
      expect(designation_account_one.balance).to eq(0)
    end
  end

  context '#import_donations' do
    it 'imports a new donation from the donor system' do
      stub_one_donation

      designation_profile.designation_accounts << designation_account_one

      expect(siebel).to receive(:add_or_update_donation)
      siebel.import_donations(designation_profile)
    end

    it 'removes a donation not in the downloaded list if list is non-empty' do
      designation_profile.designation_accounts << designation_account_one
      create(:donation, remote_id: '1-IGQAP', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 17))
      create(:donation, remote_id: '1-IGQAM', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 18))
      stub_one_donation
      stub_no_donations_on_date(Date.new(2012, 12, 17))

      expect do
        siebel.send(:import_donations, designation_profile)
      end.to change { designation_account_one.donations.count }.by(-1)
    end

    it 'removes at most 3 donations per import' do
      designation_profile.designation_accounts << designation_account_one
      4.times do |i|
        create(:donation, remote_id: "#{i}-IGQAP", donor_account: donor_account,
                          designation_account: designation_account_one, donation_date: Date.new(2012, 12, 17))
      end
      create(:donation, remote_id: '1-IGQAM', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 18))
      stub_one_donation
      stub_no_donations_on_date(Date.new(2012, 12, 17))

      expect do
        siebel.send(:import_donations, designation_profile)
      end.to change { designation_account_one.donations.count }.by(-3)
    end

    it 'does not remove donations if the result from Siebel is empty' do
      create(:donation, remote_id: '1-IGQAP', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 18))

      stub_donations('[]')
      stub_no_donations_on_date(Date.new(2012, 12, 18))

      designation_profile.designation_accounts << designation_account_one

      expect do
        siebel.send(:import_donations, designation_profile)
      end.to_not change(Donation, :count)
    end

    it 'does not remove a donation if it has appeal info' do
      designation_profile.designation_accounts << designation_account_one
      appeal = create(:appeal)
      create(:donation, remote_id: '1-IGQAP', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 17),
                        appeal: appeal)
      create(:donation, remote_id: '1-IGQAM', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 18),
                        appeal: appeal)
      stub_one_donation
      stub_no_donations_on_date(Date.new(2012, 12, 17))

      expect do
        siebel.send(:import_donations, designation_profile)
      end.to_not change(Donation, :count)
    end

    it 'does not remove a manually entered donation if it is not in the download list' do
      designation_profile.designation_accounts << designation_account_one
      appeal = create(:appeal)
      create(:donation, remote_id: nil, donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 17),
                        appeal: appeal)
      create(:donation, remote_id: '1-IGQAM', donor_account: donor_account,
                        designation_account: designation_account_one, donation_date: Date.new(2012, 12, 18),
                        appeal: appeal)
      stub_one_donation
      stub_no_donations_on_date(Date.new(2012, 12, 17))

      expect do
        siebel.send(:import_donations, designation_profile)
      end.to_not change(Donation, :count)
    end

    def stub_one_donation
      donations_json = [
        { id: '1-IGQAM', amount: '100.00', designation: designation_account_one.designation_number,
          donorId: donor_account.account_number, donationDate: '2012-12-18',
          postedDate: '2012-12-21', paymentMethod: 'Check', channel: 'Mail',
          campaignCode: '000000' }
      ].to_json
      stub_donations(donations_json)
    end

    def stub_donations(donations_json)
      today = Date.today.strftime('%Y-%m-%d')
      stub_request(:get, "#{wsapi}/donations?designations=#{designation_account_one.designation_number}&"\
                   "posted_date_end=#{today}&response_timeout=60000&posted_date_start=2004-01-01")
        .to_return(body: donations_json)
      stub_request(:get, "#{wsapi}/donations?designations=#{designation_account_one.designation_number}&"\
                   "donation_date_end=#{today}&response_timeout=60000&donation_date_start=2004-01-01")
        .to_return(body: donations_json)
    end

    def stub_no_donations_on_date(date)
      date_str = date.strftime('%Y-%m-%d')
      stub_request(:get, "#{wsapi}/donations?designations=#{designation_account_one.designation_number}&"\
                   "donors=#{donor_account.account_number}&end_date=#{date_str}&"\
                   "response_timeout=60000&start_date=#{date_str}")
        .to_return(body: '[]')
    end
  end

  context '#find_or_create_designation_account' do
    it "creates a designation account when it can't find one" do
      expect do
        siebel.send(:find_or_create_designation_account, '1', designation_profile,
                    name: 'foo')
      end.to change { DesignationAccount.count }.by(1)
    end

    it 'updates an existing designation account' do
      designation_account_one.save

      expect do
        siebel.send(:find_or_create_designation_account, designation_account_one.designation_number, designation_profile,
                    name: 'foo')
      end.not_to change { DesignationAccount.count }

      expect(designation_account_one.reload.name).to eq('foo')
    end
  end

  context '#add_or_update_donation' do
    let(:siebel_donation) { SiebelDonations::Donation.new(Oj.load('{ "id": "1-IGQAM", "amount": "100.00", "designation": "' + designation_account_one.designation_number + '", "donorId": "' + donor_account.account_number + '", "donationDate": "2012-12-18", "postedDate": "2012-12-21", "paymentMethod": "Check", "channel": "Mail", "campaignCode": "000000" }')) }

    before do
      designation_account_one.save
      designation_profile.designation_accounts << designation_account_one
    end

    it 'creates a new donation' do
      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.to change { Donation.count }.by(1)
    end

    it 'updates an existing donation with a remote_id' do
      donation = create(:donation, remote_id: '1-IGQAM', tnt_id: nil, donor_account: donor_account, amount: 5, designation_account: designation_account_one)

      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.not_to change { Donation.count }

      expect(donation.reload.amount).to eq(100.00)
    end

    it 'updates an existing donation with a tnt_id' do
      donation = create(:donation, remote_id: nil, tnt_id: '1-IGQAM', donor_account: donor_account, amount: 5, designation_account: designation_account_one)

      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.not_to change { Donation.count }

      expect(donation.reload.amount).to eq(100.00)
    end

    it 'updates an existing donation that does not have a remote_id or tnt_id' do
      donation = create(:donation, remote_id: nil, tnt_id: nil, donor_account: donor_account, amount: 100.00, donation_date: Date.parse('2012-12-18'), designation_account: designation_account_one)

      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.not_to change { Donation.count }

      expect(donation.reload.remote_id).to eq('1-IGQAM')
    end

    it 'imports multiple donations that were made on the same day, by the same donor, and of the same amount' do
      siebel_donation_one = SiebelDonations::Donation.new(Oj.load(%({ "id": "1-IGQAM", "amount": "100.00", "designation": "#{designation_account_one.designation_number}", "donorId": "#{donor_account.account_number}", "donationDate": "2012-12-18", "postedDate": "2012-12-21", "paymentMethod": "Check", "channel": "Mail", "campaignCode": "000000" })))
      siebel_donation_two = SiebelDonations::Donation.new(Oj.load(%({ "id": "1-MHEBN", "amount": "100.00", "designation": "#{designation_account_one.designation_number}", "donorId": "#{donor_account.account_number}", "donationDate": "2012-12-18", "postedDate": "2012-12-21", "paymentMethod": "Check", "channel": "Mail", "campaignCode": "000000" })))

      expect { siebel.send(:add_or_update_donation, siebel_donation_one, designation_account_one, designation_profile) }.to change { Donation.count }.from(0).to(1)
      expect { siebel.send(:add_or_update_donation, siebel_donation_two, designation_account_one, designation_profile) }.to change { Donation.count }.from(1).to(2)
    end

    it "fetches the donor from siebel if the donor isn't already on this account list" do
      donor_account.destroy
      stub_request(:get, "#{wsapi}/donors?ids=MyString&response_timeout=60000")
        .to_return(body: '[{ "id": "602506447", "accountName": "Hillside Evangelical Free Church"}]', headers: {})

      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.to change { DonorAccount.count }.by(1)
    end

    it 'uses the find donation service' do
      donation = create(:donation, remote_id: nil, tnt_id: nil, donor_account: donor_account,
                                   amount: 100.00, donation_date: Date.parse('2012-12-18'),
                                   designation_account: designation_account_one)

      expect_any_instance_of(DonationImports::Base::FindDonation).to receive(:find_and_merge).and_return(donation)
      expect do
        siebel.send(:add_or_update_donation, siebel_donation, designation_account_one, designation_profile)
      end.to_not change { Donation.count }
    end
  end

  context '#import_donors' do
    before do
      designation_profile.designation_accounts << designation_account_one

      stub_request(:get, "#{wsapi}/donors?account_address_filter=primary&contact_email_filter=all&contact_filter=all&contact_phone_filter=all&having_given_to_designations=#{designation_account_one.designation_number}&response_timeout=60000")
        .to_return(body: '[{"id":"602506447","accountName":"HillsideEvangelicalFreeChurch","type":"Business","updatedAt":"' + Date.today.to_s(:db) + '"}]')
    end

    it 'imports a new donor from the donor system' do
      expect(siebel).to receive(:add_or_update_donor_account)
      expect(siebel).to receive(:add_or_update_company)
      siebel.import_donors(designation_profile, Date.today)
    end

    it 'does not error if donor account has multiple primary addresses' do
      donor_account.update_column(:account_number, '602506447')
      address1 = create(:address, primary_mailing_address: true)
      address2 = create(:address)
      donor_account.addresses << address1
      donor_account.addresses << address2
      address2.update_column(:primary_mailing_address, true)
      siebel.import_donors(designation_profile, Date.today)
    end
  end

  context '#add_or_update_donor_account' do
    it 'adds a new donor account' do
      expect(siebel).to receive(:add_or_update_person)
      expect(siebel).to receive(:add_or_update_address).twice

      expect do
        siebel.send(:add_or_update_donor_account, account_list, siebel_donor, designation_profile)
      end.to change { DonorAccount.count }.by(1)
    end

    it 'updates an existing donor account' do
      donor_account = create(:donor_account, organization: org, account_number: siebel_donor.id)

      expect(siebel).to receive(:add_or_update_person)
      expect(siebel).to receive(:add_or_update_address).once.with(anything, donor_account, donor_account)
      expect(siebel).to receive(:add_or_update_address).once.with(anything, anything, donor_account)

      expect do
        siebel.send(:add_or_update_donor_account, account_list, siebel_donor, designation_profile)
      end.not_to change { DonorAccount.count }

      expect(donor_account.reload.name).to eq(siebel_donor.account_name)
    end

    it "doesn't create a new contact if one already exists with this account number" do
      donor_account = create(:donor_account, organization: org, account_number: siebel_donor.id)
      contact = create(:contact, account_list: account_list)
      donor_account.contacts << contact

      expect do
        siebel.send(:add_or_update_donor_account, account_list, siebel_donor, designation_profile)
      end.not_to change { Contact.count }
    end

    it "skips people who haven't been updated since the last download" do
      donor_account = create(:donor_account, organization: org, account_number: siebel_donor.id)

      expect(donor_account).to receive(:link_to_contact_for).and_return(contact)
      allow(org).to receive_message_chain(:donor_accounts, :where, :first_or_initialize)
        .and_return(donor_account)
      allow(contact).to receive_message_chain(:people, :present?).and_return(true)

      expect(siebel).to_not receive(:add_or_update_person)

      expect do
        siebel.send(:add_or_update_donor_account, account_list, siebel_donor, designation_profile, Time.zone.now)
      end.not_to change { Person.count }

      expect(donor_account.reload.name).to eq(siebel_donor.account_name)
    end
  end

  context '#add_or_update_person' do
    let(:siebel_person) { SiebelDonations::Contact.new(Oj.load('{"id":"1-3GJ-2744","primary":true,"firstName":"Jean","preferredName":"Jean","lastName":"Spansel","title":"Mrs","sex":"F"}')) }

    it 'adds a new person' do
      siebel_person_with_rels = SiebelDonations::Contact.new(Oj.load('{"id":"1-3GJ-2744","primary":true,"firstName":"Jean","preferredName":"Jean","lastName":"Spansel","title":"Mrs","sex":"F","emailAddresses":[{"updatedAt":"' + 1.day.ago.to_s(:db) + '","id":"1-CEX-8425","type":"Home","primary":true,"email":"markmarthaspansel@gmail.com"}],"phoneNumbers":[{"id":"1-BTE-2524","type":"Work","primary":true,"phone":"510/656-7873"}]}'))

      expect(siebel).to receive(:add_or_update_email_address).twice
      expect(siebel).to receive(:add_or_update_phone_number).twice

      expect do
        siebel.send(:add_or_update_person, siebel_person_with_rels, donor_account, contact)
      end.to change { Person.count }.by(2)
    end

    it 'skips phone numbers and emails that have not been updated' do
      siebel_person_with_rels = SiebelDonations::Contact.new(
        Oj.load('{"id":"1-3GJ-2744","primary":true,"firstName":"Jean","preferredName":"Jean","lastName":"Spansel",
                  "title":"Mrs","sex":"F","emailAddresses":[
                    {"updatedAt":"' + 1.day.ago.to_s(:db) + '","id":"1-CEX-8425","type":"Home","primary":true,
                      "email":"markmarthaspansel@gmail.com"}],
                  "phoneNumbers":[{"updatedAt":"' + 1.day.ago.to_s(:db) + '","id":"1-BTE-2524","type":"Work",
                        "primary":true,"phone":"510/656-7873"}]}')
      )

      expect(contact).to receive(:add_person).and_return(person)

      allow(person).to receive_message_chain(:phone_numbers, :present?).and_return(true)
      allow(person).to receive_message_chain(:email_addresses, :present?).and_return(true)

      expect(siebel).to_not receive(:add_or_update_email_address)
      expect(siebel).to_not receive(:add_or_update_phone_number)

      siebel.send(:add_or_update_person, siebel_person_with_rels, donor_account, contact, Time.zone.now)
    end

    it 'leaves the user modified name fields alone when it updates a person' do
      mp = MasterPerson.create
      MasterPersonSource.create(master_person_id: mp.id, organization_id: org.id, remote_id: siebel_person.id)
      p = create(:person, master_person_id: mp.id)
      donor_account.people << p
      contact.people << p

      expect do
        siebel.send(:add_or_update_person, siebel_person, donor_account, contact)
      end.not_to change { Person.count }

      expect(p.reload.legal_first_name).to_not eq(siebel_person.first_name)
    end

    it 'find and updates an old-style remote_id' do
      # Set up a person with the old style remote id
      mp = MasterPerson.create
      mps = MasterPersonSource.create(master_person_id: mp.id, organization_id: org.id, remote_id: donor_account.account_number + '-1')

      expect do
        siebel.send(:add_or_update_person, siebel_person, donor_account, contact)
      end.not_to change { MasterPersonSource.count }

      expect(mps.reload.remote_id).to eq(siebel_person.id)
    end

    it 'maps sex=M to gender=male' do
      siebel_person = SiebelDonations::Contact.new(Oj.load('{"id":"1-3GJ-2744","primary":true,"firstName":"Jean","preferredName":"Jean","lastName":"Spansel","title":"Mrs","sex":"M"}'))

      p = siebel.send(:add_or_update_person, siebel_person, donor_account, contact).first
      expect(p.gender).to eq('male')
    end

    it 'maps sex=Undetermined to gender=nil' do
      siebel_person = SiebelDonations::Contact.new(Oj.load('{"id":"1-3GJ-2744","primary":true,"firstName":"Jean","preferredName":"Jean","lastName":"Spansel","title":"Mrs","sex":"Undetermined"}'))

      p = siebel.send(:add_or_update_person, siebel_person, donor_account, contact).first
      expect(p.gender).to be_nil
    end
  end

  context '#add_or_update_address' do
    let(:siebel_address) { SiebelDonations::Address.new(Oj.load('{"id":"1-IQ5-1006","type":"Mailing","primary":true,"seasonal":false,"address1":"1697 Marabu Way","city":"Fremont","state":"CA","zip":"94539-3683","updated_at":"2014-02-14"}')) }
    let(:source_donor_account) { create(:donor_account) }

    it 'adds a new address' do
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to change { Address.count }.by(1)

      expect(contact.addresses.count).to eq(1)
      address = contact.addresses.first
      attrs = { street: '1697 Marabu Way', city: 'Fremont', state: 'CA', country: nil, postal_code: '94539-3683',
                start_date: Date.new(2014, 2, 14), source: 'Siebel' }
      expect(address.attributes.symbolize_keys.slice(*attrs.keys)).to eq(attrs)
    end

    it 'updates an existing address' do
      address = create(:address, addressable: contact, remote_id: siebel_address.id)
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.not_to change { Address.count }

      expect(address.reload.postal_code).to eq(siebel_address.zip)
    end

    it 'raises an error if the address is invalid' do
      siebel_address = SiebelDonations::Address.new(Oj.load('{"id":"1-IQ5-1006","type":"BAD_TYPE"}'))
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to raise_error(/Validation failed/)
    end

    it "doesn't add a new address when there is a matching deleted address" do
      create(:address, addressable: contact, street: siebel_address.address1, city: siebel_address.city,
                       state: siebel_address.state, postal_code: siebel_address.zip, deleted: true)
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.not_to change { Address.count }
    end

    it 'sets the source donor account' do
      source_donor_account = create(:donor_account)
      siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      expect(contact.addresses.first.source_donor_account).to eq(source_donor_account)
    end

    it 'sets the address as primary if none are marked primary' do
      contact.addresses << create(:address, historic: true, primary_mailing_address: false)
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to change(Address, :count).from(1).to(2)
      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be true

      # survives a second import
      contact.reload
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count)
      expect(contact.addresses.reload.where(primary_mailing_address: true).count).to eq(1)
    end

    it 'does not set the address as primary if a non-matching non-Siebel address is primary' do
      manual_address = create(:address, primary_mailing_address: true, source: Address::MANUAL_SOURCE)
      contact.addresses << manual_address
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to change(Address, :count).from(1).to(2)
      expect(manual_address.primary_mailing_address).to be true
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be false

      # survives a second import
      contact.reload
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count)
      expect(manual_address.primary_mailing_address).to be true
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be false
    end

    it 'sets the address as primary if a Siebel address from the same donor account is primary' do
      donor_account = create(:donor_account)
      contact.addresses << create(:address, primary_mailing_address: true, source: 'Siebel',
                                            source_donor_account: donor_account)
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, donor_account)
      end.to change(Address, :count).from(1).to(2)
      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be true

      # survives a second import
      contact.reload
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count)
      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be true
    end

    it 'does not make address primary if a non-matching Siebel address from a different donor account is primary' do
      donor_account1 = create(:donor_account)
      donor_account2 = create(:donor_account)
      contact.addresses << create(:address, primary_mailing_address: true, source: 'Siebel',
                                            source_donor_account: donor_account1)
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, donor_account2)
      end.to change(Address, :count).from(1).to(2)
      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be false

      # survives a second import
      contact.reload
      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count)
      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)
      expect(contact.addresses.where.not(remote_id: nil).first.primary_mailing_address).to be false
    end

    def stub_siebel_address_smarty
      address_smarty = '[{"delivery_line_1":"1697 Marabu Way","components":{"city_name":"Fremont",'\
        '"state_abbreviation":"CA","zipcode":"94539","plus4_code":"3683"}}]'
      stub_request(:get, %r{https://api\.smartystreets\.com/.*}).to_return(body: address_smarty)
    end

    it 'matches and updates an address with the same master but different formatting' do
      stub_siebel_address_smarty

      contact.addresses << create(:address, primary_mailing_address: true, master_address: nil,
                                            street: '1697 Marabu', city: 'Fremont', state: 'CA', postal_code: '94539')

      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count).from(1)

      address = contact.addresses.first
      expect(address.street).to eq('1697 Marabu Way')
      expect(address.postal_code).to eq('94539-3683')
      expect(address.primary_mailing_address).to be true
      expect(address.source).to eq('Siebel')
      expect(address.remote_id).to_not be_nil
      expect(address.source_donor_account).to eq(source_donor_account)
      expect(address.start_date).to eq(Date.new(2014, 2, 14))
    end

    it 'prefers match by place and disconnects remote id of old address now points to new place' do
      stub_siebel_address_smarty

      new_manual_address = create(:address, primary_mailing_address: true, master_address: nil,
                                            street: '1697 Marabu', city: 'Fremont', state: 'CA', postal_code: '94539',
                                            source: 'Manual', start_date: Date.new(2014, 1, 1), remote_id: nil)

      old_remote_address = create(:address, primary_mailing_address: false, remote_id: '1-IQ5-1006')

      contact.addresses << new_manual_address
      contact.addresses << old_remote_address

      expect do
        siebel.send(:add_or_update_address, siebel_address, contact, source_donor_account)
      end.to_not change(Address, :count).from(2)

      expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)

      new_manual_address.reload
      expect(new_manual_address.street).to eq('1697 Marabu Way')
      expect(new_manual_address.postal_code).to eq('94539-3683')
      expect(new_manual_address.primary_mailing_address).to be true
      expect(new_manual_address.source).to eq('Siebel')
      expect(new_manual_address.remote_id).to eq('1-IQ5-1006')
      expect(new_manual_address.source_donor_account).to eq(source_donor_account)
      expect(new_manual_address.start_date).to eq(Date.new(2014, 2, 14))
      expect(new_manual_address.primary_mailing_address).to be true

      old_remote_address.reload
      expect(old_remote_address.primary_mailing_address).to be false
      expect(old_remote_address.remote_id).to be_nil
    end
  end

  context '#add_or_update_phone_number' do
    let(:siebel_phone_number) { SiebelDonations::PhoneNumber.new(Oj.load('{"id":"1-CI7-4832","type":"Work","primary":true,"phone":"408/269-4782"}')) }

    it 'adds a new phone number' do
      expect do
        siebel.send(:add_or_update_phone_number, siebel_phone_number, person)
      end.to change { PhoneNumber.count }.by(1)
    end

    it 'updates an existing phone number' do
      pn = create(:phone_number, person: person, remote_id: siebel_phone_number.id)

      expect do
        siebel.send(:add_or_update_phone_number, siebel_phone_number, person)
      end.not_to change { PhoneNumber.count }

      expect(pn.reload.number).to eq('+14082694782')
    end
  end

  context '#add_or_update_email_address' do
    let(:siebel_email) { SiebelDonations::EmailAddress.new(Oj.load('{"id":"1-CEX-8425","type":"Home","primary":true,"email":"markmarthaspansel@gmail.com"}')) }

    it 'adds a new email address' do
      expect do
        siebel.send(:add_or_update_email_address, siebel_email, person)
      end.to change { EmailAddress.count }.by(1)
    end

    it 'updates an existing email address' do
      email = create(:email_address, person: person, remote_id: siebel_email.id)

      expect do
        siebel.send(:add_or_update_email_address, siebel_email, person)
      end.not_to change { EmailAddress.count }

      expect(email.reload.email).to eq(siebel_email.email)
    end
  end

  context '#add_or_update_company' do
    it 'adds a new company' do
      expect do
        siebel.send(:add_or_update_company, account_list, siebel_donor, donor_account)
      end.to change { Company.count }.by(1)
    end

    it 'updates an existing company' do
      mc = create(:master_company, name: siebel_donor.account_name)
      company = create(:company, master_company: mc)
      account_list.companies << company

      expect do
        siebel.send(:add_or_update_company, account_list, siebel_donor, donor_account)
      end.not_to change { Company.count }

      expect(company.reload.name).to eq(siebel_donor.account_name)
    end
  end

  context '#profiles_with_designation_numbers' do
    it 'returns a hash of attributes' do
      expect(siebel).to receive(:profiles).and_return(
        [SiebelDonations::Profile.new('id' => '', 'name' => 'Profile 1',
                                      'designations' => [{ 'number' => '1234' }])]
      )
      expect(siebel.profiles_with_designation_numbers)
        .to eq([{ name: 'Profile 1', code: '', designation_numbers: ['1234'] }])
    end
  end
end
