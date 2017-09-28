require 'rails_helper'

describe TntImport do
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:user) { create(:user) }
  let(:tnt_import) { create(:tnt_import, override: true, user: user) }
  let(:import) { TntImport.new(tnt_import) }
  let(:contact) { create(:contact) }
  let(:contact_rows) { xml.tables['Contact'] }
  let(:task_rows) { xml.tables['Task'] }
  let(:task_contact_rows) { xml.tables['TaskContact'] }
  let(:history_rows) { xml.tables['History'] }
  let(:history_contact_rows) { xml.tables['HistoryContact'] }
  let(:property_rows) { xml.tables['Property'] }

  before do
    stub_smarty_streets
    user.preferences['time_zone'] = ActiveSupport::TimeZone.all.last
    user.save
  end

  describe '#xml' do
    it 'returns an Xml object' do
      import = TntImport.new(create(:tnt_import))
      expect(import.xml).to be_a TntImport::Xml
      expect(import.xml.tables.keys).to eq %w(Appeal Contact Designation Group GroupContact History HistoryContact
                                              HistoryResult LikelyToGive Login LoginProfile LoginProfileDesignation PendingAction Picture Property Region
                                              RegionLocation Task TaskContact TaskReason TaskType)
      expect(import.xml.version).to eq 3.0
    end
  end

  context '#import contacts with multiple donor accounts in multiple existing contacts' do
    before do
      account_list = create(:account_list)
      designation_profile = create(:designation_profile)
      organization = org_for_code('CCC-USA')
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
    it 'creates a new contact from a non-donor' do
      import = TntImport.new(create(:tnt_import_non_donor))
      expect do
        import.send(:import_contacts)
      end.to change(Contact, :count).by(1)
    end

    it "doesn't create duplicate people when importing the same list twice" do
      import = TntImport.new(create(:tnt_import_non_donor))
      import.send(:import_contacts)

      expect do
        import.send(:import_contacts)
      end.not_to change(Person, :count)
    end

    it 'associates referrals and imports no_appeals field' do
      expect do
        import.send(:import)
      end.to change(ContactReferral, :count).by(1)
      expect(Contact.first.no_appeals).to be true
    end

    context 'referred by contact cannot be found' do
      it 'adds the referred by name into the contact notes' do
        expect do
          import.send(:import)
        end.to change { Contact.last&.notes }.from(nil).to("call for amount \n \nReferred by: Steve and Lisa Moss")
      end

      it 'adds a tag so that the contact can be found' do
        expect do
          import.send(:import)
        end.to change { Contact.last&.tag_list }.from(nil).to(['missing tnt referred by'])
      end
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
        expect do
          import.send(:import_contacts)
        end.to change { contact.reload.status }.from('Ask in Future').to('Partner - Pray')
      end

      describe 'primary address behavior' do
        def import_with_addresses
          @address = create(:address, primary_mailing_address: true)
          contact.addresses << @address
          contact.save
          expect(contact.addresses.where(primary_mailing_address: true).count).to eq(1)

          expect do
            import.send(:import_contacts)
          end.not_to change { contact.addresses.where(primary_mailing_address: true).count }

          expect do # make sure it survives a second import
            import.send(:import_contacts)
          end.not_to change { contact.addresses.where(primary_mailing_address: true).count }
        end

        it 'changes the primary address of an existing contact' do
          import_with_addresses
          expect(@address.reload.primary_mailing_address).to be false
        end

        it 'does not change the primary address of an existing contact if not override' do
          tnt_import.update_column(:override, false)
          import_with_addresses
          expect(@address.reload.primary_mailing_address).to be true
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
          expect(@email_before_import.reload.primary).to be false
        end

        it 'does not change the primary email of an existing contact if not override' do
          import.send(:import_contacts)
          expect(@email_before_import.reload.primary).to be true
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
          person = Person.find_by(first_name: 'Bob')
          expect(person.email_addresses.where(primary: true).count).to eq(1)
          expect(person.email_addresses.where(primary: true).first.email).to eq('fake2@example.com')
        end
      end

      describe 'primary phone behavior' do
        before do
          @person = create(:person, first_name: 'Bob', last_name: 'Doe')
          @person.phone_number = { number: '212-456-7890', primary: true }
          @person.save
          @contact = create(:contact, account_list: @account_list, name: 'Doe, Bob and Dawn')
          @contact.people << @person
          @phone_before_import = @person.phone_numbers.first

          tnt_import.update_column(:override, false)
        end

        it 'changes the primary phone of an existing contact if override' do
          tnt_import.update_column(:override, true)
          import.send(:import_contacts)
          expect(@phone_before_import.reload.primary).to be false
        end

        it 'does not change the primary phone of an existing contact if not override' do
          import.send(:import_contacts)
          expect(@phone_before_import.reload.primary).to be true
        end

        it 'sets the primary phone if override not set and no primary was set for the person' do
          @phone_before_import.update_column(:primary, false)
          import.send(:import_contacts)
          expect(@person.phone_numbers.where(primary: true).count).to eq(1)
          expect(@person.phone_numbers.where(primary: true).first.number).to eq('+12123337890')
        end

        it 'sets the primary phone if override not set and no person existed' do
          @contact.destroy
          import.send(:import_contacts)
          person = Person.find_by(first_name: 'Bob')
          expect(person.phone_numbers.where(primary: true).count).to eq(1)
          expect(person.phone_numbers.where(primary: true).first.number).to eq('+12123337890')
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
          expect(john_numbers).to include('+15155551234') # home
          expect(john_numbers).to include('+12132111111')
          expect(john_numbers).to include('+15155559771;301')
          expect(jane_numbers.size).to eq(2)
          expect(jane_numbers).to include('+15155551234') # home
          expect(jane_numbers).to include('+12122222222')
        end
      end
    end

    it 'does not import very old dates' do
      import.send(:import_contacts)
      contact = Contact.first
      expect(contact.next_ask).not_to eq Date.parse('1899-12-30')
      expect(contact.pledge_start_date).not_to eq Date.parse('1899-12-30')
      expect(contact.last_activity).not_to eq Date.parse('1899-12-30')
      expect(contact.last_appointment).not_to eq Date.parse('1899-12-30')
      expect(contact.last_letter).not_to eq Date.parse('1899-12-30')
      expect(contact.last_phone_call).not_to eq Date.parse('1899-12-30')
      expect(contact.last_pre_call).not_to eq Date.parse('1899-12-30')
      expect(contact.last_thank).not_to eq Date.parse('1899-12-30')
    end

    it 'imports a contact even if their donor account had no name' do
      org = create(:organization)
      create(:donor_account, account_number: '413518908', organization: org, name: nil)
      create(:designation_profile, account_list: tnt_import.account_list, organization: org)
      expect do
        import.send(:import_contacts)
      end.to change(Contact, :count).by(2)
    end

    it 'imports a contact people details even if the contact is not a donor' do
      import = TntImport.new(create(:tnt_import_non_donor))
      expect do
        import.send(:import_contacts)
      end.to change(Person, :count).by(1)
    end

    it 'matches an existing contact with leading zeros in their donor account' do
      donor_account = create(:donor_account, account_number: '000139111', name: nil)

      organization = org_for_code('CCC-USA')
      organization.donor_accounts << donor_account
      organization.save

      contact.donor_accounts << donor_account
      contact.save

      account_list = build(:account_list)
      account_list.designation_profiles << create(:designation_profile, organization: organization)
      account_list.contacts << contact
      account_list.save

      import = TntImport.new(create(:tnt_import_short_donor_code, account_list: account_list))
      import.send(:import_contacts)

      # Should match existing contact based on the donor account with leading zeros
      expect(DonorAccount.all.count).to eq(1)
      expect(Contact.all.count).to eq(1)

      # The donor account name should get set to the contact name if it was nil
      expect(donor_account.reload.name).to eq 'Smith, Joe and Jane'
    end
  end

  context '#import_tasks' do
    it 'creates a new task' do
      expect do
        task_ids_by_tnt_task_id = import.send(:import_tasks)
        task = Task.find(task_ids_by_tnt_task_id.first[1])
        expect(task.remote_id).to eq('-1918558789')
      end.to change(Task, :count).by(1)
    end

    it 'sets start_at' do
      task_ids_by_tnt_task_id = import.send(:import_tasks)
      task = Task.find(task_ids_by_tnt_task_id.first[1])
      expect(task.start_at).to eq(tnt_import.user.time_zone.parse('2006-09-09 16:30:00'))
    end

    it 'updates an existing task' do
      create(:task, source: 'tnt', remote_id: task_rows.first['id'], account_list: tnt_import.account_list)

      expect do
        import.send(:import_tasks)
      end.not_to change(Task, :count)
    end

    it 'associates a contact with the task' do
      expect do
        import.send(:import_tasks, task_contact_rows.first['ContactID'] => contact.id)
      end.to change(ActivityContact, :count).by(1)
    end

    it 'adds notes as a task comment' do
      task = create(:task, source: 'tnt', remote_id: task_rows.first['id'], account_list: tnt_import.account_list)
      import.send(:import_tasks)
      expect(task.comments.first.body).to eq('Notes')
    end

    it 'does not add duplicate comments' do
      task = create(:task, source: 'tnt', remote_id: task_rows.first['id'], account_list: tnt_import.account_list)
      task.comments.create!(body: 'Notes')
      import.send(:import_tasks)
      expect(task.comments.count).to eq(1)
    end

    it 'sets the task as complete' do
      expect(TntImport::TntCodes).to receive(:task_status_completed?).and_return(true)
      task_ids_by_tnt_task_id = import.send(:import_tasks)
      task = Task.find(task_ids_by_tnt_task_id.first[1])
      expect(task.completed).to eq(true)
    end
  end

  context '#import groups' do
    it 'imports groups as tags' do
      account_list = build(:account_list)
      import = TntImport.new(create(:tnt_import_groups, account_list: account_list))
      import.send(:import_contacts)

      expect(Contact.all.count).to eq(1)
      contact = Contact.all.first
      expect(contact.tag_list.sort).to eq(%w(category-1-comma group-with-dave-comma testers))
    end
  end

  context '#import_appeals' do
    def test_appeal_import(import)
      account_list = import.account_list

      account_list.users << create(:user)
      @offline_org = create(:offline_org)
      account_list.users.first.organization_accounts << create(:organization_account, organization: @offline_org)

      tnt_import = TntImport.new(import)

      expect do
        tnt_import.send(:import)
      end.to change(Appeal, :count).from(0).to(1)
      appeal = Appeal.first
      expect(appeal.name).to eq('CSU')
      expect(appeal.created_at).to eq(Time.zone.local(2005, 5, 21, 12, 56, 40))
      expect(appeal.contacts.pluck(:name)).to eq(['Smith, John and Jane'])

      donation = appeal.donations.first
      expect(donation.tnt_id).to eq('ICWMY')
      expect(donation.appeal).to eq(appeal)
      expect(donation.appeal_amount).to eq(25)

      # Survies the second import even if you rename the appeal
      # Also check that it updates created_at to match tnt
      appeal.update(name: 'Test new name', created_at: Time.now)
      expect do
        tnt_import.send(:import)
      end.to_not change(Appeal, :count).from(1)
      expect(donation.appeal_amount).to eq(25)
      appeal.reload
      expect(appeal.created_at).to eq(Time.zone.local(2005, 5, 21, 12, 56, 40))
      expect(appeal.contacts.pluck(:name)).to eq(['Smith, John and Jane'])
    end

    context 'version 3.1 and lower, appeals are called "Appeal"' do
      it 'imports an appeal as well as its contacts and donations' do
        test_appeal_import(create(:tnt_import_3_0_appeals))
      end
    end

    context 'version 3.2 and higher, appeals are called "Campaign"' do
      it 'imports an appeal as well as its contacts and donations' do
        test_appeal_import(create(:tnt_import_3_2_campaigns))
      end
    end

    it 'does not error if an appeal has no contacts' do
      create(:appeal, tnt_id: -723_622_290, account_list: tnt_import.account_list)
      contacts_by_tnt_appeal_id = {}
      expect { import.send(:import_appeals, contacts_by_tnt_appeal_id) }.to_not raise_error
      expect(Appeal.count).to eq(1)
      expect(AppealContact.count).to eq(0)
    end

    it 'imports appeals before it imports gifts' do
      expect(import).to receive(:import_appeals).ordered
      expect(import).to receive(:import_offline_org_gifts).ordered
      import.import
    end
  end

  context '#import_history' do
    it 'creates a new completed task' do
      expect do
        import.send(:import_history)
      end.to change(Task, :count).by(1)
    end

    it 'marks an existing task as completed' do
      task = create(:task, source: 'tnt', remote_id: history_rows.first['id'], account_list: tnt_import.account_list, completed: false)

      expect { import.send(:import_history) }.not_to change(Task, :count)

      task.reload
      expect(task.completed).to eq(true)
      expect(task.completed_at.utc).to eq(tnt_import.user.time_zone.parse('2004-08-26 19:00:00').utc)
    end

    it 'accociates a contact with the task' do
      expect do
        import.send(:import_history, history_contact_rows.first['ContactID'] => contact)
      end.to change(ActivityContact, :count).by(1)
    end

    it 'associates contacts with tnt appeal ids' do
      tnt_import = TntImport.new(create(:tnt_import_3_0_appeals))
      contact_ids_by_tnt_appeal_id = tnt_import.send(:import_history, import.send(:import_contacts))
      expect(contact_ids_by_tnt_appeal_id.size).to eq(1)
      contact_ids = contact_ids_by_tnt_appeal_id['-2079150908']
      expect(contact_ids.size).to eq(1)
      expect(contact_ids[0]).to_not be_nil
      expect(Contact.find(contact_ids[0]).name).to eq('Smith, John and Jane')
    end
  end

  context 'importing designations from multiple orgs' do
    it 'assigns correct organization to import designation numbers' do
      ptc = org_for_code('PTC-CAN')
      cru = org_for_code('CCC-USA')

      expect do
        create(:tnt_import_multi_org).send(:import)
      end.to change(Contact, :count).by(2)

      contacts = Contact.order(:name).to_a
      expect(contacts.size).to eq 2
      jane = contacts.first
      expect(jane.donor_accounts.count).to eq 2
      jane.donor_accounts.all? { |da| expect(da.organization).to eq ptc }
      john = contacts.second
      expect(john.donor_accounts.count).to eq 1
      expect(john.donor_accounts.first.organization).to eq cru
      expect(john.donor_accounts.first.name).to eq 'Smith, John'
      john_donor_address = john.donor_accounts.first.addresses.first
      expect(john_donor_address.street).to eq '12345 Crescent'
      expect(john_donor_address.country).to eq 'Canada'
    end
  end

  context 'version support' do
    context 'version 3.2 and higher' do
      before { tnt_import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

      it 'imports' do
        expect { import.import }.to change { Contact.all.count }.from(0).to(3)
      end
    end
  end
end
