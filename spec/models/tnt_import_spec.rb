require 'spec_helper'

describe TntImport do
  let(:xml) { import.read_xml(tnt_import.file.file.file) }
  let(:tnt_import) { create(:tnt_import, override: true) }
  let(:import) { TntImport.new(tnt_import) }
  let(:contact) { create(:contact) }
  let(:contact_rows) { Array.wrap(xml['Database']['Tables']['Contact']['row']) }
  let(:task_rows) { Array.wrap(xml['Database']['Tables']['Task']['row']) }
  let(:task_contact_rows) { Array.wrap(xml['Database']['Tables']['TaskContact']['row']) }
  let(:history_rows) { Array.wrap(xml['Database']['Tables']['History']['row']) }
  let(:history_contact_rows) { Array.wrap(xml['Database']['Tables']['HistoryContact']['row']) }
  let(:property_rows) { Array.wrap(xml['Database']['Tables']['Property']['row']) }

  before do
    stub_request(:get, /api\.smartystreets\.com\/.*/)
      .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '{}', headers: {})
  end

  context '#import contacts with multiple donor accounts in multiple existing contacts' do
    before do
      account_list = create(:account_list)
      designation_profile = create(:designation_profile)
      organization = create(:organization)
      designation_profile.organization = organization
      account_list.designation_profiles << designation_profile

      john = create(:contact, name: 'Doe, John')
      john_donor = create(:donor_account, account_number: '444444444')
      john.donor_accounts << john_donor
      organization.donor_accounts << john_donor
      account_list.contacts << john

      john_and_jane = create(:contact, name: 'Doe, John and Jane')
      john_and_jane_donor = create(:donor_account, account_number: '555555555')
      john_and_jane.donor_accounts << john_and_jane_donor
      organization.donor_accounts << john_and_jane_donor
      account_list.contacts << john_and_jane

      @import = create(:tnt_import_multi_donor_accounts, account_list: account_list)
      @tnt_import = TntImport.new(@import)
    end

    it 'imports and merges existing contacts by donor accounts if set to override' do
      @import.update_column(:override, true)
      @tnt_import.send(:import_contacts)
      expect(Contact.all.count).to eq(1)
    end

    it 'imports and merges existing contacts by donor accounts if not set to override' do
      @import.update_column(:override, false)
      @tnt_import.send(:import_contacts)
      expect(Contact.all.count).to eq(1)
    end
  end

  context '#import_contacts' do
    it 'associates referrals' do
      import.should_receive(:add_or_update_donor_accounts).and_return([create(:donor_account)])
      import.should_receive(:add_or_update_donor_accounts).and_return([create(:donor_account)])
      expect {
        import.send(:import_contacts)
      }.to change(ContactReferral, :count).by(1)
    end

    context 'updating an existing contact' do
      before do
        @account_list = create(:account_list)
        tnt_import.account_list = @account_list
        tnt_import.save
        TntImport.new(tnt_import)
        contact.tnt_id = 1_620_699_916
        contact.status = 'Ask in Future'
        contact.account_list = @account_list
        contact.save
      end

      it 'updates an existing contact' do
        import.should_receive(:add_or_update_donor_accounts).and_return([create(:donor_account)])
        import.should_receive(:add_or_update_donor_accounts).and_return([create(:donor_account)])
        expect {
          import.send(:import_contacts)
        }.to change { contact.reload.status }.from('Ask in Future').to('Partner - Pray')
      end

      describe 'primary address behavior' do
        def import_with_addresses
          donor_account_one = create(:donor_account)
          donor_account_two = create(:donor_account)
          import.should_receive(:add_or_update_donor_accounts).and_return([donor_account_one])
          import.should_receive(:add_or_update_donor_accounts).and_return([donor_account_two])
          import.should_receive(:add_or_update_donor_accounts).and_return([donor_account_one])
          import.should_receive(:add_or_update_donor_accounts).and_return([donor_account_two])
          @address = create(:address, primary_mailing_address: true)
          contact.addresses << @address
          contact.save
          expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)

          expect {
            import.send(:import_contacts)
          }.not_to change { contact.addresses.where(primary_mailing_address: true).count }

          expect { # make sure it survives a second import
            import.send(:import_contacts)
          }.not_to change { contact.addresses.where(primary_mailing_address: true).count }
        end

        it 'changes the primary address of an existing contact' do
          import_with_addresses
          expect(@address.reload.primary_mailing_address).to be_false
        end

        it 'does not change the primary address of an existing contact if not override' do
          tnt_import.update_column(:override, false)
          import_with_addresses
          expect(@address.reload.primary_mailing_address).to be_true
        end
      end

      describe 'primary email behavior' do
        before do
          @person = create(:person, first_name: 'Bob', last_name: 'Doe')
          @person.email_address = { email: 'test@example.com', primary: true }
          @person.save
          @contact = create(:contact, account_list: @account_list, name: 'Doe, Bob and Dawn')
          @contact.people << @person
          @email_before_import = @person.email_addresses.first

          tnt_import.update_column(:override, false)
        end

        it 'changes the primary email of an existing contact if override' do
          tnt_import.update_column(:override, true)
          import.send(:import_contacts)
          expect(@email_before_import.reload.primary).to be_false
        end

        it 'does not change the primary email of an existing contact if not override' do
          import.send(:import_contacts)
          expect(@email_before_import.reload.primary).to be_true
        end

        it 'sets the primary email if override not set and no primary was set for the person' do
          @email_before_import.update_column(:primary, false)
          import.send(:import_contacts)
          expect(@person.email_addresses.where(primary: true).count).to eq(1)
          expect(@person.email_addresses.where(primary: true).first.email).to eq('fake2@example.com')
        end

        it 'sets the primary email if override not set and no person existed' do
          @contact.destroy
          import.send(:import_contacts)
          person = Person.find_by_first_name('Bob')
          expect(person.email_addresses.where(primary: true).count).to eq(1)
          expect(person.email_addresses.where(primary: true).first.email).to eq('fake2@example.com')
        end
      end

      describe 'primary phone behavior' do
        before do
          @person = create(:person, first_name: 'Bob', last_name: 'Doe')
          @person.phone_number = { number: '123-456-7890', primary: true }
          @person.save
          @contact = create(:contact, account_list: @account_list, name: 'Doe, Bob and Dawn')
          @contact.people << @person
          @phone_before_import = @person.phone_numbers.first

          tnt_import.update_column(:override, false)
        end

        it 'changes the primary phone of an existing contact if override' do
          tnt_import.update_column(:override, true)
          import.send(:import_contacts)
          expect(@phone_before_import.reload.primary).to be_false
        end

        it 'does not change the primary phone of an existing contact if not override' do
          import.send(:import_contacts)
          expect(@phone_before_import.reload.primary).to be_true
        end

        it 'sets the primary phone if override not set and no primary was set for the person' do
          @phone_before_import.update_column(:primary, false)
          import.send(:import_contacts)
          expect(@person.phone_numbers.where(primary: true).count).to eq(1)
          expect(@person.phone_numbers.where(primary: true).first.number).to eq('+12223337890')
        end

        it 'sets the primary phone if override not set and no person existed' do
          @contact.destroy
          import.send(:import_contacts)
          person = Person.find_by_first_name('Bob')
          expect(person.phone_numbers.where(primary: true).count).to eq(1)
          expect(person.phone_numbers.where(primary: true).first.number).to eq('+12223337890')
        end
      end

      describe 'spouse/primary person phone import' do
        it 'puts home phone in both, but only primary or spouse phones in individual people' do
          john = create(:person, first_name: 'John', last_name: 'Smith')
          jane = create(:person, first_name: 'Jane', last_name: 'Smith')
          contact.people << john
          contact.people << jane
          import.send(:import_contacts)

          john_numbers = john.reload.phone_numbers.pluck(:number)
          jane_numbers = jane.reload.phone_numbers.pluck(:number)
          expect(john_numbers.size).to eq(3)
          expect(john_numbers).to include('+15555551234') # home
          expect(john_numbers).to include('+11111111111')
          expect(john_numbers).to include('(555) 555-9771 ext. 301')
          expect(jane_numbers.size).to eq(2)
          expect(jane_numbers).to include('+15555551234') # home
          expect(jane_numbers).to include('+12222222222')
        end
      end
    end

    it 'does not cause an error and increases contact count for case with first email not preferred' do
      row = YAML.load(File.new(Rails.root.join('spec/fixtures/tnt/tnt_row_multi_email.yaml')).read)
      expect { import.send(:import_contact, row) }.to change(Contact, :count).by(1)
    end

    it 'imports a contact even if their donor account had no name' do
      org = create(:organization)
      create(:donor_account, account_number: '413518908', organization: org, name: nil)
      create(:designation_profile, account_list: tnt_import.account_list, organization: org)
      expect {
        import.send(:import_contacts)
      }.to change(Contact, :count).by(2)
    end

    it 'imports a contact people details even if the contact is not a donor' do
      import = TntImport.new(create(:tnt_import_non_donor))
      expect {
        import.send(:import_contacts)
      }.to change(Person, :count).by(1)
    end

    it 'matches an existing contact with leading zeros in their donor account' do
      donor_account = create(:donor_account, account_number: '000139111')

      organziation = build(:organization)
      organziation.donor_accounts << donor_account
      organziation.save

      contact.donor_accounts << donor_account
      contact.save

      account_list = build(:account_list)
      account_list.designation_profiles << create(:designation_profile, organization: organziation)
      account_list.contacts << contact
      account_list.save

      import = TntImport.new(create(:tnt_import_short_donor_code, account_list: account_list))
      import.send(:import_contacts)

      # Should match existing contact based on the donor account with leading zeros
      expect(DonorAccount.all.count).to eq(1)
      expect(Contact.all.count).to eq(1)
    end
  end

  context '#tnt_email_preferred?' do
    it 'interprets the tntmpd bit vector for PreferredEmailTypes to return true/false for prefix and email num' do
      {
        [{ 'PreferredEmailTypes' => '0' }, 1, ''] => false,
        [{ 'PreferredEmailTypes' => '0' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '2' }, 1, ''] => true,
        [{ 'PreferredEmailTypes' => '2' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '6' }, 1, ''] => true,
        [{ 'PreferredEmailTypes' => '6' }, 2, ''] => true,
        [{ 'PreferredEmailTypes' => '8' }, 1, ''] => false,
        [{ 'PreferredEmailTypes' => '8' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '8' }, 3, ''] => true,
        [{ 'PreferredEmailTypes' => '2' }, 1, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '2' }, 1, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '16' }, 1, 'Spouse'] => true,
        [{ 'PreferredEmailTypes' => '16' }, 2, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '24' }, 1, 'Spouse'] => true,
        [{ 'PreferredEmailTypes' => '24' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '24' }, 3, ''] => true,
        [{ 'PreferredEmailTypes' => '32' }, 2, 'Spouse'] => true
      }.each do |inputs, preferred|
        row, email_num, person_prefix = inputs
        expect(import.send(:tnt_email_preferred?, row, email_num, person_prefix)).to eq(preferred)
      end
    end
  end

  context '#update_person_emails' do
    let(:person) { create(:person) }

    it 'imports emails and sets the first preferred and valid one to primary' do
      row = { 'SpouseEmail1' => 'a@a.com', 'SpouseEmail2' => 'b@b.com', 'SpouseEmail3' => 'c@c.com',
        'SpouseEmail1IsValid' => 'true', 'SpouseEmail2IsValid' => 'false', 'SpouseEmail3IsValid' => 'true' }
      prefix = 'Spouse'
      expect(import).to receive(:tnt_email_preferred?).and_return(false, true)
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.size).to eq(3)
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['a@a.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['b@b.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['c@c.com', true])
    end

    it 'only marks one email as primary even if there are multiple that are preferred and valid' do
      prefix = ''
      row = { 'Email1' => 'a@a.com', 'Email2' => 'b@b.com', 'Email1IsValid' => 'true', 'Email2IsValid' => 'true' }
      expect(import).to receive(:tnt_email_preferred?).at_least(:once).and_return(true)
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.size).to eq(2)
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['a@a.com', true])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['b@b.com', false])
    end

    it 'marks tnt "invalid" email addresses as historic in mpdx' do
      prefix = ''
      row = { 'Email1' => 'a@a.com', 'Email1IsValid' => 'false' }
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.first.historic).to be_true

      person.email_addresses.destroy_all

      prefix = 'Spouse'
      row = { 'SpouseEmail1' => 'a@a.com', 'SpouseEmail2' => 'b@b.com',
              'SpouseEmail1IsValid' => 'true', 'SpouseEmail2IsValid' => 'false' }
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.count).to eq(2)
      expect(person.email_addresses.map { |e| [e.email, e.historic] }).to include(['a@a.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.historic] }).to include(['b@b.com', true])
    end
  end

  context '#update_person_phones' do
    let(:person) { create(:person) }

    it 'marks tnt "invalid" phone numbers as historic in mpdx' do
      row = { 'HomePhone2' => '222-222-2222', 'SpouseMobilePhone' => '333-333-3333',
        'PhoneIsValidMask' => '4096' }
      prefix = 'Spouse'
      import.send(:update_person_phones, person, row, prefix)
      expect(person.phone_numbers.count).to eq(2)
      expect(person.phone_numbers.map { |p| [p.number, p.historic] }).to include(['+12222222222', true])
      expect(person.phone_numbers.map { |p| [p.number, p.historic] }).to include(['+13333333333', false])
    end
  end

  context '#update_contact' do
    it 'updates notes correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq("Principal\nHas run into issues with Campus Crusade in the past...  Was told couldn't be involved because hadn't been baptized as an adult.")
    end

    it 'updates newsletter preferences correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.send_newsletter).to eq('Physical')
    end

    it 'sets the address region' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.addresses.first.region).to eq('State College')
    end
  end

  context '#update_person_attributes' do
    it 'imports a phone number for a person' do
      person = Person.new
      expect {
        person = import.send(:update_person_attributes, person, contact_rows.first)
      }.to change(person.phone_numbers, :length).by(3)
    end
  end

  context '#add_or_update_donor_accounts' do
    let(:organization) { create(:organization) }
    let(:designation_profile) { create(:designation_profile, organization: organization) }

    it 'finds an existing donor account' do
      create(:donor_account, organization: organization, account_number: contact_rows.first['OrgDonorCodes'])

      expect {
        import.send(:add_or_update_donor_accounts, contact_rows.first, designation_profile)
      }.not_to change(DonorAccount, :count)
    end

    it 'finds an existing contact' do
      tnt_import.account_list.contacts << create(:contact, name: contact_rows.first['FileAs'])
      tnt_import.account_list.save

      expect {
        import.send(:add_or_update_donor_accounts, contact_rows.first, designation_profile)
      }.not_to change(Contact, :count)
    end

    it 'creates a new donor account' do
      expect {
        import.send(:add_or_update_donor_accounts, contact_rows.first, designation_profile)
      }.to change(DonorAccount, :count).by(1)
    end

    it 'creates a new contact' do
      expect {
        import.send(:import_contacts)
      }.to change(Contact, :count).by(2)
    end

    it 'creates a new contact from a non-donor' do
      import = TntImport.new(create(:tnt_import_non_donor))
      expect {
        import.send(:import_contacts)
      }.to change(Contact, :count).by(1)
    end

    it "doesn't create duplicate people when importing the same list twice" do
      import = TntImport.new(create(:tnt_import_non_donor))
      import.send(:import_contacts)

      expect {
        import.send(:import_contacts)
      }.not_to change(Person, :count)
    end

  end

  context '#import_tasks' do
    it 'creates a new task' do
      expect {
        tasks = import.send(:import_tasks)
        tasks.first[1].remote_id.should_not be_nil
      }.to change(Task, :count).by(1)
    end

    it 'updates an existing task' do
      create(:task, source: 'tnt', remote_id: task_rows.first['id'], account_list: tnt_import.account_list)

      expect {
        import.send(:import_tasks)
      }.not_to change(Task, :count).by(1)
    end

    it 'accociates a contact with the task' do
      expect {
        import.send(:import_tasks,  task_contact_rows.first['ContactID'] => contact)
      }.to change(ActivityContact, :count).by(1)
    end

    it 'adds notes as a task comment' do
      task = create(:task, source: 'tnt', remote_id: task_rows.first['id'], account_list: tnt_import.account_list)

      import.send(:import_tasks)

      task.activity_comments.first.body.should == 'Notes'
    end
  end

  context '#import_history' do
    it 'creates a new completed task' do
      expect {
        tasks = import.send(:import_history)
        tasks.first[1].remote_id.should_not be_nil
      }.to change(Task, :count).by(1)
    end

    it 'marks an existing task as completed' do
      create(:task, source: 'tnt', remote_id: history_rows.first['id'], account_list: tnt_import.account_list)

      expect {
        import.send(:import_history)
      }.not_to change(Task, :count).by(1)
    end

    it 'accociates a contact with the task' do
      expect {
        import.send(:import_history,  history_contact_rows.first['ContactID'] => contact)
      }.to change(ActivityContact, :count).by(1)
    end

  end

  context '#import_settings' do
    it 'updates monthly goal' do
      import.should_receive(:create_or_update_mailchimp).and_return

      expect {
        import.send(:import_settings)
      }.to change(tnt_import.account_list, :monthly_goal).from(nil).to(6300)
    end
  end

  context '#create_or_update_mailchimp' do
    it 'creates a mailchimp account' do
      expect {
        import.send(:create_or_update_mailchimp, 'asdf', 'asasdfdf-us4')
      }.to change(MailChimpAccount, :count).by(1)
    end

    it 'updates a mailchimp account' do
      tnt_import.account_list.create_mail_chimp_account(api_key: '5', primary_list_id: '6')

      expect {
        import.send(:create_or_update_mailchimp, '1', '2')
      }.to change(tnt_import.account_list.mail_chimp_account, :api_key).from('5').to('2')
    end
  end

  context '#import gifts for offline orgs' do
    before do
      @account_list = create(:account_list)
      @offline_org = create(:offline_org)
      @user = create(:user)
      @user.organization_accounts << create(:organization_account, organization: @offline_org)
      @account_list.users << @user

      @import = create(:tnt_import_gifts, account_list: @account_list)
      @tnt_import = TntImport.new(@import)
    end

    it 'does not import gifts for an online org or multiple orgs' do
      stub_request(:post, 'http://foo:bar@example.com/profiles')
        .with(body: { 'Action' => 'Profiles', 'Password' => 'Test1234', 'UserName' => 'test@test.com' })
        .to_return(body: '')

      @user.organization_accounts.destroy_all

      online_org = create(:organization)
      @user.organization_accounts << create(:organization_account, organization: online_org)
      expect { @tnt_import.import  }.to_not change(Donation, :count).from(0)

      @user.organization_accounts.destroy_all
      @user.organization_accounts << create(:organization_account, organization: @offline_org)
      @user.organization_accounts << create(:organization_account, organization: create(:offline_org))
      expect { @tnt_import.import  }.to_not change(Donation, :count).from(0)
    end

    it 'imports gifts for a single offline org' do
      expect { @tnt_import.import  }.to change(Donation, :count).from(0).to(2)
      contact = Contact.first
      fields = [:donation_date, :amount, :tendered_amount, :tendered_currency]
      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(*fields) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50,
                                   tendered_amount: 50, tendered_currency: 'USD')
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25,
                                   tendered_amount: 25, tendered_currency: 'USD')

      expect(contact.last_donation_date).to eq(Date.new(2013, 11, 21))
      expect(contact.first_donation_date).to eq(Date.new(2013, 11, 20))
      expect(contact.total_donations).to eq(75.0)

      expect(contact.donor_accounts.count).to eq(1)
      donor_account = contact.donor_accounts.first
      expect(donor_account.total_donations).to eq(75.0)
      expect(donor_account.name).to eq('Test, Dave')
    end

    it 'finds a unique donor number for new contacts' do
      # Make sure it does a numeric search not an alphabetic one to find 10 as the max and not 9.
      @offline_org.donor_accounts.create(account_number: '10')
      @offline_org.donor_accounts.create(account_number: '9')
      expect { @tnt_import.import  }.to change(Donation, :count).from(0).to(2)
      Donation.all.each do |donation|
        expect(donation.donor_account.account_number).to eq('11')
      end
    end

    it 'does not re-import the same gifts multiple times but adds new gifts in existing donor accounts' do
      expect { @tnt_import.import  }.to change(Donation, :count).from(0).to(2)

      expect(DonorAccount.first.account_number).to eq('1')

      import2 = create(:tnt_import_gifts_added, account_list: @account_list)
      tnt_import2 = TntImport.new(import2)

      expect { tnt_import2.import  }.to change(Donation, :count).from(2).to(3)

      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(:donation_date, :amount) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50)
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25)
      expect(donations).to include(donation_date: Date.new(2013, 11, 22), amount: 100)

      contact = Contact.first
      expect(contact.last_donation_date).to eq(Date.new(2013, 11, 22))
      expect(contact.first_donation_date).to eq(Date.new(2013, 11, 20))
      expect(contact.total_donations).to eq(175.0)

      expect(contact.donor_accounts.count).to eq(1)
      donor_account = contact.donor_accounts.first
      expect(donor_account.account_number).to eq('1')
      expect(donor_account.total_donations).to eq(175.0)
    end
  end

  context '#import groups' do
    it 'imports groups as tags' do
      account_list = build(:account_list)
      import = TntImport.new(create(:tnt_import_groups, account_list: account_list))
      import.send(:import_contacts)

      expect(Contact.all.count).to eq(1)
      contact = Contact.all.first
      expect(contact.tag_list).to eq(%w(testers category-1 group-with-dave))
    end
  end

  context '#import' do
    it 'performs an import' do
      import.should_receive(:xml).and_return('foo')
      import.should_receive(:import_contacts).and_return
      import.should_receive(:import_tasks).and_return
      import.should_receive(:import_history).and_return
      import.should_receive(:import_settings).and_return
      import.import
    end
  end
end
