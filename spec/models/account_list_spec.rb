require 'spec_helper'

describe AccountList do
  context '.find_or_create_from_profile' do
    let(:org_account) { create(:organization_account) }
    let(:profile) { create(:designation_profile, user_id: org_account.person_id, organization: org_account.organization) }

    it 'should create a new account list if none is found' do
      da = create(:designation_account, organization: org_account.organization)
      profile.designation_accounts << da
      expect do
        AccountList.find_or_create_from_profile(profile, org_account)
      end.to change(AccountList, :count).by(1)
    end

    it 'should not create a new account list if one is found' do
      da = create(:designation_account, organization: org_account.organization)
      profile.designation_accounts << da
      account_list = create(:account_list)
      profile2 = create(:designation_profile, account_list: account_list)
      profile2.designation_accounts << da
      expect(AccountList.find_or_create_from_profile(profile, org_account))
        .to eq(account_list)
    end
  end

  context '#send_account_notifications' do
    it 'checks all notification types' do
      expect(NotificationType).to receive(:check_all)
      AccountList.new.send(:send_account_notifications)
    end
  end

  context '#valid_mail_chimp_account' do
    let(:account_list) { build(:account_list) }

    it 'returns true if there is a mailchimp associated with this account list that has a valid primary list' do
      mail_chimp_account = double(active?: true, primary_list: { id: 'foo', name: 'bar' })
      expect(account_list).to receive(:mail_chimp_account).twice.and_return(mail_chimp_account)
      expect(account_list.valid_mail_chimp_account).to eq(true)
    end

    it 'returns a non-true value when primary list is not present' do
      mail_chimp_account = double(active?: true, primary_list: nil)
      expect(account_list).to receive(:mail_chimp_account).twice.and_return(mail_chimp_account)
      expect(account_list.valid_mail_chimp_account).not_to eq(true)
    end

    it 'returns a non-true value when mail_chimp_account is not active' do
      mail_chimp_account = double(active?: false, primary_list: nil)
      expect(account_list).to receive(:mail_chimp_account).once.and_return(mail_chimp_account)
      expect(account_list.valid_mail_chimp_account).not_to eq(true)
    end

    it 'returns a non-true value when there is no mail_chimp_account' do
      expect(account_list).to receive(:mail_chimp_account).once.and_return(nil)
      expect(account_list.valid_mail_chimp_account).not_to eq(true)
    end
  end

  context '#top_partners' do
    let(:account_list) { create(:account_list) }

    it 'returns the top 10 donors on your list' do
      11.times do |i|
        account_list.contacts << create(:contact, total_donations: i)
      end

      expect(account_list.top_partners).to eq(account_list.contacts.order(:id)[1..-1].reverse)
    end
  end

  context '#people_with_birthdays' do
    let(:account_list) { create(:account_list) }
    let(:contact) { create(:contact) }
    let(:person) { create(:person, birthday_month: 8, birthday_day: 30) }

    before do
      contact.people << person
      account_list.contacts << contact
    end

    it 'handles a date range where the start and end day are in the same month' do
      expect(account_list.people_with_birthdays(Date.new(2012, 8, 29), Date.new(2012, 8, 31))).to eq([person])
    end

    it 'handles a date range where the start and end day are in different months' do
      expect(account_list.people_with_birthdays(Date.new(2012, 8, 29), Date.new(2012, 9, 1))).to eq([person])
    end

    it 'excludes deceased people' do
      person.update(deceased: true)
      expect(account_list.people_with_birthdays(Date.new(2012, 8, 29), Date.new(2012, 8, 31))).to be_empty
    end
  end

  context '#contacts_with_anniversaries' do
    let(:account_list) { create(:account_list) }
    let(:contact) { create(:contact) }
    let(:person) { create(:person, anniversary_month: 8, anniversary_day: 30) }

    before do
      contact.people << person
      account_list.contacts << contact
    end

    it 'handles a date range where the start and end day are in the same month' do
      expect(account_list.contacts_with_anniversaries(Date.new(2012, 8, 29), Date.new(2012, 8, 31)))
        .to eq([contact])
    end

    it 'handles a date range where the start and end day are in different months' do
      expect(account_list.contacts_with_anniversaries(Date.new(2012, 8, 29), Date.new(2012, 9, 1)))
        .to eq([contact])
    end

    it 'excludes contacts who have any deceased people in them' do
      contact.people << create(:person, deceased: true)
      expect(account_list.contacts_with_anniversaries(Date.new(2012, 8, 29), Date.new(2012, 9, 1)))
        .to be_empty
    end

    it 'only includes people with anniversaries in the loaded people association' do
      person_without_anniversary = create(:person)
      contact.people << person_without_anniversary

      contact_with_anniversary = account_list
                                 .contacts_with_anniversaries(Date.new(2012, 8, 29), Date.new(2012, 9, 1))
                                 .first
      expect(contact_with_anniversary.people.size).to eq 1
      expect(contact_with_anniversary.people).to include(person)
    end
  end

  context '#users_combined_name' do
    let(:account_list) { create(:account_list, name: 'account list') }

    it 'combines first and second user names and gives account list name if no uers' do
      {
        [] => 'account list',
        [{ first_name: 'John' }] => 'John',
        [{ first_name: 'John', last_name: 'Doe' }] => 'John Doe',
        [{ first_name: 'John', last_name: 'Doe' }, { first_name: 'Jane', last_name: 'Doe' }] => 'John and Jane Doe',
        [{ first_name: 'John', last_name: 'A' }, { first_name: 'Jane', last_name: 'B' }] => 'John A and Jane B',
        [{ first_name: 'John' }, { first_name: 'Jane' }, { first_name: 'Paul' }] => 'John and Jane'
      }.each do |people_attrs, name|
        Person.destroy_all
        people_attrs.each do |person_attrs|
          account_list.users << create(:user, person_attrs)
        end
        expect(account_list.users_combined_name).to eq(name)
      end
    end
  end

  context '#physical_newsletter_csv' do
    it 'does not cause an error or give an empty string' do
      contact = create(:contact, name: 'Doe, John', send_newsletter: 'Both')
      contact.addresses << create(:address)
      account_list = create(:account_list)
      account_list.contacts << contact

      csv_rows = CSV.parse(account_list.physical_newsletter_csv)
      expect(csv_rows.size).to eq(3)
      csv_rows.each_with_index do |row, index|
        expect(row[0]).to eq('Contact Name') if index == 0
        expect(row[0]).to eq('Doe, John') if index == 1
        expect(row[0]).to be_nil if index == 2
      end
    end
  end

  context '#user_emails_with_names' do
    let(:account_list) { create(:account_list) }

    it 'handles the no users case and no email fine' do
      expect(account_list.user_emails_with_names).to be_empty
      account_list.users << create(:user)
      expect(account_list.user_emails_with_names).to be_empty
    end

    it 'gives the names of the users with the email addresses' do
      user1 = create(:user, first_name: 'John')
      user1.email = 'john@a.com'
      user1.save
      user2 = create(:user, first_name: 'Jane', last_name: 'Doe')
      user2.email = 'jane@a.com'
      user2.save
      user3 = create(:user)

      account_list.users << user1
      expect(account_list.user_emails_with_names.first).to eq('John <john@a.com>')

      account_list.users << user2
      account_list.users << user3
      expect(account_list.user_emails_with_names.size).to eq(2)
      expect(account_list.user_emails_with_names).to include('John <john@a.com>')
      expect(account_list.user_emails_with_names).to include('Jane Doe <jane@a.com>')
    end
  end

  context '#no_activity_since' do
    let(:account_list) { create(:account_list) }

    it 'filters contacts' do
      contact1 = create(:contact, account_list: account_list)
      contact1.tasks << create(:task, completed: true, completed_at: 1.day.ago)
      contact2 = create(:contact, account_list: account_list)
      no_act_list = account_list.no_activity_since(6.months.ago)
      expect(no_act_list).to_not include contact1
      expect(no_act_list).to include contact2
    end
  end

  context '#churches' do
    let(:account_list) { create(:account_list) }

    it 'returns all churches' do
      create(:contact, account_list: account_list, church_name: 'church2')
      create(:contact, account_list: account_list, church_name: 'church1')
      create(:contact, account_list: account_list, church_name: 'church1')
      expect(account_list.churches).to eq %w(church1 church2)
    end
  end

  context '#contact_tags and #activity_tags' do
    let(:account_list) { create(:account_list) }

    it 'returns all churches' do
      create(:contact, account_list: account_list, tag_list: ['tag2'])
      create(:contact, account_list: account_list, tag_list: ['tag1'])
      create(:contact, tag_list: ['other tag'])

      create(:activity, account_list: account_list, tag_list: ['t_tag2'])
      create(:activity, account_list: account_list, tag_list: ['t_tag1'])
      create(:activity, tag_list: ['other tag'])

      expect(account_list.contact_tags).to eq %w(tag1 tag2)
      expect(account_list.activity_tags).to eq %w(t_tag1 t_tag2)
    end
  end

  context '#contact_tags and #activity_tags' do
    let(:account_list) { create(:account_list) }

    it 'returns all churches' do
      contact = create(:contact, account_list: account_list)
      contact.addresses << create(:address, city: 'City1', state: 'WI')
      contact.addresses << create(:address, city: 'City2', state: 'FL')
      # contact.save!

      expect(account_list.cities).to eq %w(City1 City2)
      expect(account_list.states).to eq %w(FL WI)
    end
  end

  context '#all_contacts' do
    let(:account_list) { create(:account_list) }

    it 'returns all churches' do
      c1 = create(:contact, account_list: account_list)
      c2 = create(:contact, account_list: account_list, status: 'Unresponsive')

      expect(account_list.all_contacts).to include c1
      expect(account_list.all_contacts).to include c2
    end
  end

  context '#merge' do
    let(:loser) { create(:account_list) }
    let(:winner) { create(:account_list) }

    it 'deletes old AccountList' do
      expect { winner.merge(loser) }.to change(AccountList, :count).by(1)
    end

    it 'merges appeals' do
      create(:appeal, account_list: loser)
      expect do
        winner.merge(loser)
      end.to change(winner.appeals.reload, :count).by(1)
    end

    it 'moves the prayer letters account from the loser if winner lacked one' do
      create(:prayer_letters_account, account_list: loser)
      winner.merge(loser)
      expect(winner.reload.prayer_letters_account).to_not be_nil
    end

    it 'leaves the winner prayer letter account if both winner and loser have one' do
      create(:prayer_letters_account, account_list: loser)
      winner_pla = create(:prayer_letters_account, account_list: winner)
      expect { winner.merge(loser) }.to change(PrayerLettersAccount, :count).to(1)
      expect(winner.reload.prayer_letters_account).to eq(winner_pla)
    end

    it 'moves designation accounts if they are missing in the winner' do
      loser.designation_accounts << create(:designation_account)
      expect { winner.merge(loser) }.to change(winner.designation_accounts, :count).from(0).to(1)
    end

    it 'does not create a duplicate if a designation account is in both winner and loser' do
      da = create(:designation_account)
      loser.designation_accounts << da
      winner.designation_accounts << da
      winner.reload
      expect(winner.designation_accounts.count).to eq(1)
    end
  end

  it 'percent calculations' do
    account_list = create(:account_list, monthly_goal: '200')
    create(:contact, pledge_amount: 100, account_list: account_list)
    create(:contact, pledge_amount: 50, pledge_received: true, account_list: account_list)

    expect(account_list.in_hand_percent).to eq 25
    expect(account_list.pledged_percent).to eq 75
  end

  context '#queue_sync_with_google_contacts' do
    let(:account_list) { create(:account_list) }
    let(:integration) { create(:google_integration, contacts_integration: true, calendar_integration: false) }

    before do
      account_list.google_integrations << integration
    end

    it 'queues a job if there is a google integration that syncs contacts' do
      account_list.queue_sync_with_google_contacts
      expect(LowerRetryWorker.jobs.size).to eq(1)
    end

    it 'does not queue if there are no google integrations with contact sync set' do
      integration.update(contacts_integration: false)
      account_list.queue_sync_with_google_contacts
      expect(LowerRetryWorker.jobs).to be_empty

      account_list.google_integrations.destroy_all
      account_list.queue_sync_with_google_contacts
      expect(LowerRetryWorker.jobs).to be_empty
    end

    it 'does not queue if is an import is running' do
      create(:import, account_list: account_list, importing: true, source: 'google')
      account_list.queue_sync_with_google_contacts
      expect(LowerRetryWorker.jobs).to be_empty
    end

    it 'does not queue if is an account is downloading' do
      account_list.users << create(:user)
      create(:organization_account, downloading: true, person: account_list.users.first)
      account_list.queue_sync_with_google_contacts
      expect(LowerRetryWorker.jobs).to be_empty
    end

    it 'does not queue if the mail chimp account is importing' do
      create(:mail_chimp_account, account_list: account_list, importing: true)
      expect do
        account_list.queue_sync_with_google_contacts
      end.to_not change(LowerRetryWorker.jobs, :size)
    end
  end

  context '#import_data' do
    let(:account_list) { create(:account_list) }
    let(:user) { create(:user) }
    let(:organization_account) { create(:organization_account) }

    before do
      account_list.users << user
      user.organization_accounts << organization_account
    end

    it 'imports data for each org account, then sends notifications and queues google contact sync' do
      expect_any_instance_of(Person::OrganizationAccount).to receive(:import_all_data)
      expect(account_list).to receive(:send_account_notifications)
      expect(account_list).to receive(:queue_sync_with_google_contacts)
      account_list.send(:import_data)
    end

    it 'does not import from org accounts with skip_downloads set' do
      organization_account.update(disable_downloads: true)
      expect_any_instance_of(Person::OrganizationAccount).to_not receive(:import_all_data)
      account_list.send(:import_data)
    end
  end

  describe 'top and bottom donor halves by pledge value' do
    subject { create(:account_list) }
    let(:high_pledger) do
      create(:contact, status: 'Partner - Financial', pledge_amount: 100)
    end
    let(:low_pledger) do
      create(:contact, status: 'Partner - Financial', pledge_amount: 600, pledge_frequency: 12)
    end
    before do
      subject.contacts << high_pledger
      subject.contacts << low_pledger
    end

    it 'calculates the top 50 percent' do
      expect(subject.reload.top_50_percent.to_a).to eq [high_pledger]
    end

    it 'calculates the bottom 50 percent' do
      expect(subject.bottom_50_percent.to_a).to eq [low_pledger]
    end
  end

  context 'with_linked_org_accounts scope' do
    let!(:org_account) { create(:organization_account) }

    it 'returns non-locked account lists with organization accounts' do
      expect(AccountList.with_linked_org_accounts).to include org_account.account_list
    end

    it 'does not return locked accounts' do
      org_account.update_column(:locked_at, 1.minute.ago)
      expect(AccountList.with_linked_org_accounts).to_not include org_account.account_list
    end
  end

  context '.update_linked_org_accounts' do
    it 'schedules the linked accounts to spread over 24 hours' do
      account_list = instance_double(AccountList)
      expect(AccountList).to receive(:with_linked_org_accounts) do
        [account_list]
      end
      expect(AsyncScheduler).to receive(:schedule_over_24h)
        .with([account_list], :import_data)

      AccountList.update_linked_org_accounts
    end
  end
end
