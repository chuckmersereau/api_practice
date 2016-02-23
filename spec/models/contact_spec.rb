require 'spec_helper'

describe Contact do
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }

  describe 'saving addresses' do
    it 'should create an address' do
      address = build(:address, addressable: nil)
      expect do
        contact.addresses_attributes = [address.attributes.with_indifferent_access.except(:id, :addressable_id, :addressable_type, :updated_at, :created_at)]
        contact.save!
      end.to change(Address, :count).by(1)
    end

    it 'should mark an address deleted' do
      address = create(:address, addressable: contact)

      contact.addresses_attributes = [{ id: address.id, _destroy: '1' }]
      contact.save!

      expect { address.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should update an address' do
      stub_request(:get, %r{https:\/\/api\.smartystreets\.com\/street-address})
        .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '[]', headers: {})

      address = create(:address, addressable: contact)
      contact.addresses_attributes = [address.attributes.merge!(street: address.street + 'boo').with_indifferent_access.except(:addressable_id, :addressable_type, :updated_at, :created_at)]
      contact.save!
      expect(contact.addresses.first.street).to eq(address.street + 'boo')
    end
  end

  describe 'saving email addresses' do
    it 'should change which email address is primary' do
      person = create(:person)
      contact.people << person
      email1 = create(:email_address, primary: true, person: person)
      email2 = create(:email_address, primary: false, person: person)

      people_attributes =
        { 'people_attributes' =>
          { '0' =>
            { 'email_addresses_attributes' =>
              {
                '0' => { 'email' => email1.email, 'primary' => '0', '_destroy' => 'false', 'id' => email1.id },
                '1' => { 'email' => email2.email, 'primary' => '1', '_destroy' => 'false', 'id' => email2.id }
              },
              'id' => person.id
            }
          }
        }
      contact.update_attributes(people_attributes)
      expect(email1.reload.primary?).to be false
      expect(email2.reload.primary?).to be true
    end
  end

  describe 'saving donor accounts' do
    it 'links to an existing donor account if one matches' do
      donor_account = create(:donor_account)
      account_list.designation_accounts << create(:designation_account, organization: donor_account.organization)
      contact.donor_accounts_attributes = { '0' => { account_number: donor_account.account_number, organization_id: donor_account.organization_id } }
      contact.save!
      expect(contact.donor_accounts).to include(donor_account)
    end

    it 'creates a new donor account' do
      expect do
        contact.donor_accounts_attributes = { '0' => { account_number: 'asdf', organization_id: create(:organization).id } }
        contact.save!
      end.to change(DonorAccount, :count).by(1)
    end

    it 'updates an existing donor account' do
      donor_account = create(:donor_account)
      donor_account.contacts << contact

      contact.donor_accounts_attributes = { '0' => { id: donor_account.id, account_number: 'asdf' } }
      contact.save!

      expect(donor_account.reload.account_number).to eq('asdf')
    end

    it 'deletes an existing donor account' do
      donor_account = create(:donor_account)
      donor_account.contacts << contact

      expect do
        contact.donor_accounts_attributes = { '0' => { id: donor_account.id, account_number: 'asdf', _destroy: '1' } }
        contact.save!
      end.to change(ContactDonorAccount, :count).by(-1)
    end

    it 'deletes an existing donor account when posting a blank account number' do
      donor_account = create(:donor_account)
      donor_account.contacts << contact

      expect do
        contact.donor_accounts_attributes = { '0' => { id: donor_account.id, account_number: '' } }
        contact.save!
      end.to change(ContactDonorAccount, :count).by(-1)
    end

    it 'saves a contact when posting a blank donor account number' do
      contact.donor_accounts_attributes = { '0' => { account_number: '', organization_id: 1 } }
      expect(contact.save).to eq(true)
    end

    it "won't let you assign the same donor account number to two contacts" do
      donor_account = create(:donor_account)
      donor_account.contacts << contact

      contact2 = create(:contact, account_list: contact.account_list)

      expect(
        contact2.update(donor_accounts_attributes: {
                          '0' => {
                            account_number: donor_account.account_number,
                            organization_id: donor_account.organization_id
                          }
                        })
      ).to eq(false)
    end
  end

  describe 'create_from_donor_account' do
    before do
      @account_list = create(:account_list)
      @donor_account = create(:donor_account)
    end

    it "should copy the donor account's addresses" do
      create(:address, addressable: @donor_account, remote_id: '1')
      expect do
        @contact = Contact.create_from_donor_account(@donor_account, @account_list)
      end.to change(Address, :count)
      expect(@contact.addresses.first.equal_to?(@donor_account.addresses.first)).to be true
      expect(@contact.addresses.first.source_donor_account).to eq(@donor_account)
      expect(@contact.addresses.first.remote_id).to eq('1')
    end
  end

  it 'should have a primary person' do
    person = create(:person)
    contact.people << person
    expect(contact.primary_or_first_person).to eq(person)
  end

  describe 'when being deleted' do
    it 'should delete people not linked to another contact' do
      contact.people << create(:person)
      expect do
        contact.destroy
      end.to change(Person, :count)
    end

    it 'should NOT delete people linked to another contact' do
      person = create(:person)
      contact.people << person
      contact2 = create(:contact, account_list: contact.account_list)
      contact2.people << person
      expect do
        contact.destroy
      end.to_not change(Person, :count)
    end

    it 'deletes associated addresses' do
      create(:address, addressable: contact)
      expect { contact.destroy }
        .to change(Address, :count).by(-1)
    end
  end

  describe '#late_by?' do
    it 'should tell if a monthly donor is late on their donation' do
      expect(contact.late_by?(2.days, 30.days)).to be true
      expect(contact.late_by?(30.days, 60.days)).to be false
      expect(contact.late_by?(60.days)).to be false
    end

    it 'should tell if an annual donor is late on their donation' do
      contact = create(:contact, pledge_frequency: 12.0, last_donation_date: 14.months.ago)
      expect(contact.late_by?(30.days, 45.days)).to be false
      expect(contact.late_by?(45.days)).to be true
    end
  end

  context '#primary_person_id=' do
    it 'should not fail if an invalid id is passed in' do
      expect do
        contact.primary_person_id = 0
      end.not_to raise_exception
    end
  end

  describe '#merge' do
    let(:loser_contact) { create(:contact, account_list: account_list) }

    it 'should move all people' do
      contact.people << create(:person)
      contact.people << create(:person, first_name: 'Jill')

      loser_contact.people << create(:person, first_name: 'Bob')

      contact.merge(loser_contact)
      expect(contact.contact_people.size).to eq(3)
    end

    it 'should not remove the loser from prayer letters service' do
      pla = create(:prayer_letters_account, account_list: account_list)
      expect(pla).to_not receive(:delete_contact)

      loser_contact.update_column(:prayer_letters_id, 'foo')

      contact.merge(loser_contact)
    end

    it "should move loser's tasks" do
      task = create(:task, account_list: contact.account_list, subject: 'Loser task')
      loser_contact.tasks << task

      contact.tasks << create(:task, account_list: contact.account_list, subject: 'Winner task')

      shared_task = create(:task, account_list: contact.account_list, subject: 'Shared Task')
      contact.tasks << shared_task
      loser_contact.tasks << shared_task

      contact.update_uncompleted_tasks_count
      expect { contact.merge(loser_contact) }
        .to change(contact, :uncompleted_tasks_count).by(1)

      expect(contact.tasks).to include(task, shared_task)
      expect(shared_task.contacts.reload).to match_array [contact]
    end

    it "should move loser's notifications" do
      notification = create(:notification, contact: loser_contact)

      contact.merge(loser_contact)

      expect(contact.notifications).to include(notification)
    end

    it 'should not duplicate referrals' do
      referrer = create(:contact)
      loser_contact.referrals_to_me << referrer
      contact.referrals_to_me << referrer

      contact.merge(loser_contact)

      expect(contact.referrals_to_me.length).to eq(1)
    end

    it 'should not remove the facebook account of a person on the merged contact' do
      loser_person = create(:person)
      loser_contact.people << loser_person
      fb = create(:facebook_account, person: loser_person)

      winner_person = create(:person, first_name: loser_person.first_name, last_name: loser_person.last_name)
      contact.people << winner_person

      contact.merge(loser_contact)

      expect(contact.people.length).to eq(1)

      expect(contact.people.first.facebook_accounts).to eq([fb])
    end

    it 'should never delete a task' do
      task = create(:task, account_list: account_list)
      loser_contact.tasks << task
      contact.tasks << task
      expect do
        expect do
          contact.merge(loser_contact)
        end.not_to change(Task, :count)
      end.to change(ActivityContact, :count).by(-1)
    end

    it 'prepend notes from loser to winner' do
      loser_contact.notes = 'asdf'
      contact.notes = 'fdsa'
      contact.merge(loser_contact)
      expect(contact.notes).to eq("fdsa\nasdf")
    end

    it 'keeps winner notes if loser has none' do
      loser_contact.notes = nil
      contact.notes = 'fdsa'
      contact.merge(loser_contact)
      expect(contact.notes).to eq('fdsa')
    end

    it 'keeps loser notes if winner has none' do
      loser_contact.notes = 'fdsa'
      contact.notes = ''
      contact.merge(loser_contact)
      expect(contact.notes).to eq('fdsa')
    end

    it 'should total the donations of the contacts' do
      designation_account = create(:designation_account)
      account_list.designation_accounts << designation_account

      loser_contact.donor_accounts << create(:donor_account, account_number: '1')
      create(:donation, amount: 500.00, donor_account: loser_contact.donor_accounts.first,
                        designation_account: designation_account)

      contact.donor_accounts << create(:donor_account, account_number: '2')
      create(:donation, amount: 300.00, donor_account: contact.donor_accounts.first,
                        designation_account: designation_account)

      # Test that donation in same donor account but different designation
      # account not counted toward contact total.
      create(:donation, amount: 200.00, donor_account: contact.donor_accounts.first,
                        designation_account: create(:designation_account))

      contact.merge(loser_contact)
      expect(contact.total_donations).to eq(800.00)
    end

    it 'should keep the least recent first donation date' do
      loser_contact.first_donation_date = '2009-01-01'
      contact.first_donation_date = '2010-01-01'
      contact.merge(loser_contact)
      expect(contact.first_donation_date).to eq(Date.parse('2009-01-01'))
    end

    it 'should keep the most recent last donation date' do
      loser_contact.last_donation_date = '2010-01-01'
      contact.last_donation_date = '2009-01-01'
      contact.merge(loser_contact)
      expect(contact.last_donation_date).to eq(Date.parse('2010-01-01'))
    end

    it 'calls merge_people for the winner' do
      expect(contact).to receive(:merge_people)
      contact.merge(loser_contact)
    end
  end

  context '#destroy' do
    before do
      create(:prayer_letters_account, account_list: account_list)
    end

    it 'deletes this person from prayerletters.com if no other contact has the prayer_letters_id' do
      stub_request(:delete, %r{www.prayerletters.com/.*})
        .to_return(status: 200, body: '', headers: {})

      prayer_letters_id = 'foo'
      contact.prayer_letters_id = prayer_letters_id
      contact.send(:delete_from_letter_services)
    end

    it "DOESN'T delete this person from prayerletters.com if another contact has the prayer_letters_id" do
      # This spec passes because no external web call is made
      prayer_letters_id = 'foo'
      contact.update_column(:prayer_letters_id, prayer_letters_id)
      create(:contact, account_list: account_list, prayer_letters_id: prayer_letters_id)
      contact.send(:delete_from_letter_services)
    end
  end

  context 'without set greeting or envelope_greeting' do
    let(:person) { create(:person) }
    let(:spouse) { create(:person, first_name: 'Jill') }

    before do
      contact.people << person
      contact.people << spouse
      contact.name = "#{person.last_name}, #{person.first_name} and #{spouse.first_name}"
      contact.save
      person.save
      spouse.save
    end

    it 'generates a greeting' do
      contact.reload
      expect(contact['greeting']).to be_nil
      expect(contact.greeting).to eq(person.first_name + ' and ' + spouse.first_name)
    end

    it 'excludes deceased person from greetings' do
      person.reload
      person.deceased = true
      person.deceased_check
      person.save
      contact.reload
      expect(contact.greeting).to eq spouse.first_name
      expect(contact.envelope_greeting).to eq(spouse.first_name + ' ' + spouse.last_name)
    end

    it 'excludes deceased spouse from greetings' do
      spouse.reload
      spouse.deceased = true
      spouse.deceased_check
      spouse.save
      contact.reload
      expect(contact.greeting).to eq person.first_name
      expect(contact.envelope_greeting).to eq(person.first_name + ' ' + person.last_name)
    end

    it 'still gives name with single deceased' do
      spouse.destroy
      contact.reload
      expect(contact.people.count).to be 1
      expect(contact.greeting).to eq person.first_name
    end

    it 'considers the spouse to be the contact with primary nil or false' do
      spouse.contact_people.first.update(primary: false)
      expect(contact.reload.spouse).to eq(spouse)
      spouse.contact_people.first.update(primary: nil)
      expect(contact.reload.spouse).to eq(spouse)

      spouse.contact_people.first.update(primary: true)
      person.contact_people.first.update(primary: false)
      expect(contact.reload.spouse).to eq(person)
    end
  end

  context '#envelope_greeting' do
    let(:primary) { create(:person, first_name: 'Bob', last_name: 'Jones', legal_first_name: 'Robert') }

    before do
      contact.update_attributes(greeting: 'Fred and Lori Doe', name: 'Fredrick & Loraine Doe')
      contact.people << primary
    end

    it 'uses contact name' do
      contact.name = 'Smith, John & Jane'
      expect(contact.envelope_greeting).to eq 'John & Jane Smith'
      contact.name = 'John & Jane Smith'
      expect(contact.envelope_greeting).to eq 'John & Jane Smith'
      contact.name = 'Smith,'
      expect(contact.envelope_greeting).to eq 'Smith'
      contact.name = 'Smith, John T and Jane F'
      expect(contact.envelope_greeting).to eq 'John T and Jane F Smith'
      contact.name = 'Doe, John and Jane (Smith)'
      expect(contact.envelope_greeting).to eq 'John Doe and Jane Smith'
      contact.name = 'Doe, John (Jonny) and Jane'
      expect(contact.envelope_greeting).to eq 'John and Jane Doe'
      contact.name = 'New Life Church'
      expect(contact.envelope_greeting).to eq 'New Life Church'
      contact.name = 'Doe, George (G)'
      expect(contact.envelope_greeting).to eq 'George Doe'
      contact.name = 'Doe, John (Johnny) and Janet (Jane)'
      expect(contact.envelope_greeting).to eq 'John and Janet Doe'
      contact.name = 'Doe, John (Johnny)'
      expect(contact.envelope_greeting).to eq 'John Doe'
    end

    it 'treats parens after a spouse as nickname if also in donor account name' do
      contact.donor_accounts << create(:donor_account, name: 'Doe, John and Janet (Jane)')
      contact.name = 'Doe, John and Janet (Jane)'
      expect(contact.envelope_greeting).to eq 'John and Janet Doe'
    end

    it 'can be overwriten' do
      spouse = create(:person, first_name: 'Jen', last_name: 'Jones')
      contact.people << spouse
      contact.reload
      expect(contact.envelope_greeting).to eq('Fredrick & Loraine Doe')

      contact.update_attributes(envelope_greeting: 'Mr and Mrs Jones')
      contact.reload
      expect(contact.envelope_greeting).to eq('Mr and Mrs Jones')
    end

    it "will add last name if person doesn't have it set" do
      primary.update_attributes(last_name: '')
      contact.reload
      expect(contact.envelope_greeting).to eq('Fredrick & Loraine Doe')
    end
  end

  context '#merge_people' do
    it 'merges people with the same trimmed first and last name case insensitive' do
      matches = {
        { first_name: 'John', last_name: 'Doe' } => { first_name: 'John', last_name: 'Doe' },
        { first_name: 'John ', last_name: 'Doe ' } => { first_name: 'John', last_name: 'Doe' },
        { first_name: 'john', last_name: 'doe' } => { first_name: 'JOHN', last_name: 'Doe' },
        { first_name: 'joHn ', last_name: 'dOe' } => { first_name: ' JOHN', last_name: ' Doe' }
      }
      matches.each do |person_attrs1, person_attrs2|
        Person.destroy_all
        contact.people << create(:person, person_attrs1)
        contact.people << create(:person, person_attrs2)
        expect do
          contact.merge_people
        end.to change(Person, :count).from(2).to(1)
      end

      non_matches = {
        { first_name: 'Jane', last_name: 'Doe' } => { first_name: 'John', last_name: 'Doe' }
      }
      non_matches.each do |person_attrs1, person_attrs2|
        Person.destroy_all
        contact.people << create(:person, person_attrs1)
        contact.people << create(:person, person_attrs2)
        expect do
          contact.merge_people
        end.to_not change(Person, :count).from(2)
      end
    end

    it 'does not error but merges if last name is nil (first name cannot be blank)' do
      contact.people << create(:person, last_name: nil)
      contact.people << create(:person, last_name: nil)
      expect do
        contact.merge_people
      end.to change(Person, :count).by(-1)
    end

    it 'does not error on second merge if their master person has been merged by first merge' do
      person1 = create(:person)
      person2 = create(:person)
      person3 = create(:person, master_person: person2.master_person)
      contact.people << person1
      contact.people << person2
      contact.people << person3

      expect { contact.merge_people }.to_not raise_error
    end
  end

  context '#sync_with_google_contacts' do
    it 'calls sync contacts on the google integration' do
      contact # create test record so the commit callbacks aren't triggered below
      create(:google_integration, contacts_integration: true, calendar_integration: false,
                                  account_list: account_list, google_account: create(:google_account))
      expect_any_instance_of(GoogleIntegration).to receive(:sync_data)
      Sidekiq::Testing.inline! { contact.send(:sync_with_google_contacts) }
    end
  end

  context '#sync_with_prayer_letters' do
    let(:pl) { create(:prayer_letters_account, account_list: account_list) }
    let(:address) { create(:address, primary_mailing_address: true) }

    before do
      stub_request(:get, %r{https://api\.smartystreets\.com/street-address/.*}).to_return(body: '[]')
      contact.account_list.prayer_letters_account = pl
      contact.send_newsletter = 'Physical'
      contact.prayer_letters_params = pl.contact_params(contact)
      contact.save
      contact.addresses << address
    end

    it 'does not queue the update if not set to receive newsletter, but deletes' do
      expect(contact).to receive(:delete_from_letter_service)
        .with(:prayer_letters)
      expect_update_queued(false) { contact.update(send_newsletter: nil) }
    end

    it 'does not queue if address missing, but deletes' do
      expect_any_instance_of(Contact).to receive(:delete_from_letter_service)
        .with(:prayer_letters)
      expect_update_queued(false) { address.update(street: nil) }
    end

    it 'queues update if relevant info changed' do
      expect(contact.prayer_letters_params).to_not eq({})
      expect_update_queued { contact.update(name: 'Not-John', greeting: 'New greeting') }
    end

    it 'queues update if queried address changed' do
      expect_update_queued { Address.first.update(street: 'changed') }
    end

    it 'queues update if address changed' do
      expect_update_queued { address.update(street: 'changed') }
    end

    it 'does not queue update if not data changed or unrelated data changed' do
      expect_update_queued(false) { contact.touch }
      expect_update_queued(false) { contact.update(notes: 'Unrelated info') }
    end

    def expect_update_queued(queued = true)
      if queued
        expect_any_instance_of(PrayerLettersAccount).to receive(:add_or_update_contact).with(contact)
      else
        expect_any_instance_of(PrayerLettersAccount).to_not receive(:add_or_update_contac).with(contact)
      end

      yield
    end
  end

  context '#sync_with_mailchimp' do
    it 'notifies the mail chimp account that it changed' do
      mc_account = build(:mail_chimp_account)
      account_list.mail_chimp_account = mc_account
      expect(mc_account).to receive(:queue_sync_contacts).with([contact.id])
      contact.send(:sync_with_mail_chimp)
    end

    it 'does not error if there is no mail chimp account' do
      expect { contact.send(:sync_with_mail_chimp) }.to_not raise_error
    end
  end

  describe 'donation methods' do
    let!(:da) { create(:designation_account) }
    let!(:account_list) { create(:account_list) }
    let!(:contact) { create(:contact, account_list: account_list) }
    let!(:donor_account) { create(:donor_account) }
    let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }
    let(:old_donation) do
      create(:donation, donor_account: donor_account, designation_account: da,
                        donation_date: Date.today << 3)
    end

    before do
      account_list.account_list_entries.create!(designation_account: da)
      contact.donor_accounts << donor_account
      contact.update_donation_totals(donation)
      contact.update_donation_totals(old_donation)
    end

    context '#designated_donations' do
      it 'gives donations whose designation is connected to the contact account list' do
        expect(contact.donations.to_a).to eq([donation, old_donation])
        donation.update(designation_account: nil)
        old_donation.update(donor_account: nil)
        expect(contact.donations).to be_empty
      end
    end

    context '#last_donation' do
      it 'returns the latest designated donation' do
        old_donation
        expect(contact.last_donation).to eq(donation)
        donation.update(designation_account: nil)
        expect(contact.last_donation).to eq(old_donation)
      end
    end

    context '#last_monthly_total' do
      it 'returns zero with no error if there are no donations' do
        Donation.destroy_all
        contact.update(last_donation_date: nil)
        expect(contact.last_monthly_total).to eq(0)
      end

      it 'returns the total of the current month if it has a donation' do
        expect(contact.last_monthly_total).to eq(9.99)
      end

      it 'returns the total of the previous month if current month has no donations' do
        contact.update(last_donation_date: nil)
        donation.update(donation_date: Date.today << 1)
        old_donation.update(donation_date: Date.today << 1)
        contact.update_donation_totals(donation)
        contact.update_donation_totals(old_donation)
        expect(contact.last_monthly_total).to eq(9.99 * 2)
      end

      it 'returns zero if the previous and current months have no donations' do
        contact.update(last_donation_date: nil)
        donation.update(donation_date: Date.today << 2)
        old_donation.update(donation_date: Date.today << 2)
        contact.update_donation_totals(donation)
        contact.update_donation_totals(old_donation)
        expect(contact.last_monthly_total).to eq(0)
      end
    end

    context '#prev_month_donation_date' do
      it 'returns nil if there are no donations' do
        Donation.destroy_all
        expect(contact.prev_month_donation_date).to be_nil
        contact.update(last_donation_date: nil)
        expect(contact.prev_month_donation_date).to be_nil
      end

      it 'returns the donation date of the donation before this month if this month has donations' do
        expect(contact.prev_month_donation_date).to eq(old_donation.donation_date)
      end

      it 'returns the donation date of the donation before last month if this month has no donations' do
        contact.update(last_donation_date: nil)
        donation.update(donation_date: Date.today << 1)
        contact.update_donation_totals(donation)
        expect(contact.prev_month_donation_date).to eq(old_donation.donation_date)
      end
    end

    context '#current_monthly_avg' do
      it 'looks at the current donation only including the previous gift' do
        old_donation.update(amount: 3)
        expect(contact.monthly_avg_current).to eq(9.99)
      end
    end

    context '#recent_monthly_avg' do
      it 'uses time between donations to calculate average' do
        expect(contact.monthly_avg_with_prev_gift).to eq(9.99 / 2)
      end

      it 'considers pledge frequency in the average' do
        contact.update(pledge_frequency: 12)
        expect(contact.monthly_avg_with_prev_gift).to eq(9.99 * 2 / 12)
      end

      it 'averages correctly even if there are multiple contact donor account records' do
        create(:contact_donor_account, contact: contact, donor_account: donor_account)
        expect(contact.monthly_avg_with_prev_gift).to eq(9.99 / 2)
      end

      it 'averages including all donations in the previous donation month' do
        old_donation.update(donation_date: old_donation.donation_date.end_of_month)
        create(:donation, donor_account: donor_account, designation_account: da,
                          donation_date: old_donation.donation_date.beginning_of_month)
        expect(contact.monthly_avg_with_prev_gift).to eq(9.99 * 3 / 4)
      end
    end

    context '#monthly_avg_from' do
      it 'sums donations from date to current (or previous) month, goes back by pledge frequency multiple' do
        expect(contact.monthly_avg_from(Date.today)).to eq(9.99)
        expect(contact.monthly_avg_from(Date.today << 2)).to eq(9.99 / 3)
        expect(contact.monthly_avg_from(Date.today << 3)).to eq(9.99 / 2)

        contact.update(pledge_frequency: 3)
        expect(contact.monthly_avg_from(Date.today)).to eq(9.99 / 3)
        expect(contact.monthly_avg_from(Date.today << 2)).to eq(9.99 / 3)
        expect(contact.monthly_avg_from(Date.today << 3)).to eq(9.99 * 2 / 6)
      end
    end

    context '#months_from_prev_to_last_donation' do
      it 'gives the months elapsed between the last donation and the last donation in a previous month' do
        expect(contact.months_from_prev_to_last_donation).to eq(3)
      end
    end
  end

  context '#find_timezone' do
    it 'returns nil if the contact has no primary address' do
      expect(contact.find_timezone).to be_nil
    end

    it 'retrieves the master address timezone if there is a primary address' do
      address = build(:address)
      allow(contact).to receive(:primary_or_first_address) { address }
      expect(address.master_address).to receive(:find_timezone).and_return('EST')
      expect(contact.find_timezone).to eq 'EST'
    end
  end

  context '#update_all_donation_totals' do
    it 'sets the total_donations field to its query result' do
      expect(contact).to receive(:total_donations_query) { 5 }
      contact.update_all_donation_totals
      expect(contact.reload.total_donations).to eq 5
    end
  end

  context '#total_donations_query' do
    it 'sums the donations for the contact' do
      designation_account = create(:designation_account)
      account_list.designation_accounts << designation_account
      donor_account = create(:donor_account)
      contact.donor_accounts << donor_account

      create(:donation, amount: 5, donor_account: donor_account,
                        designation_account: designation_account)

      # It shouldn't count this donation since it has no designation
      create(:donation, amount: 10, donor_account: donor_account)

      expect(contact.total_donations_query).to eq 5
    end
  end

  context '#mailing_address' do
    it 'gives a new address if contact only has a historic address' do
      contact.addresses << create(:address, street: '1', historic: true)
      expect(contact.mailing_address.street).to be_nil
    end
  end

  context '#pledge_currency_symbol' do
    context 'with account_list#currency ""' do
      it 'returns default currency' do
        account_list.update(currency: '')
        expect(contact.pledge_currency_symbol).to eq '$'
      end
    end

    context 'with account list currency not in twitter list' do
      it 'returns currency string' do
        # Some currencies come in from data server with their
        # non-official labels, e.g. Kenyan shillings are officially KES, but
        # may come in as KSH (which doesn't exist in the Twitter list)
        account_list.update(currency: 'KSH')
        allow(TwitterCldr::Shared::Currencies)
          .to receive(:for_code).with('KSH') { nil }
        expect(contact.pledge_currency_symbol).to eq 'KSH'
      end
    end
  end
end
