require 'spec_helper'
require Rails.root.join('db', 'seeders', 'notification_types_seeder.rb')

describe AccountList do
  before do
    NotificationTypesSeeder.new.seed # Specs depend on NotificationType records.
  end

  context '#send_account_notifications' do
    it 'checks all notification types' do
      expect(NotificationType).to receive(:check_all).and_return({})
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

    it 'runs dup balance fix' do
      expect(DesignationAccount::DupByBalanceFix).to receive(:deactivate_dups)

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

  context '#update_partner_statuses' do
    it 'guesses the status for contacts based on giving history' do
      account_list = create(:account_list)
      designation = create(:designation_account)
      account_list.designation_accounts << designation
      financial_partner = create(:contact, account_list: account_list, status: nil,
                                           pledge_amount: nil, pledge_frequency: nil)
      financial_donor = create(:donor_account)
      financial_partner.donor_accounts << financial_donor
      create(:donation, amount: 50, channel: 'Recurring', donor_account: financial_donor,
                        designation_account: designation, donation_date: 1.month.ago)
      special_partner = create(:contact, account_list: account_list, status: nil)
      special_donor = create(:donor_account)
      special_partner.donor_accounts << special_donor
      create(:donation, amount: 50, channel: 'Check', donor_account: special_donor,
                        designation_account: designation, donation_date: 1.month.ago)

      account_list.update_partner_statuses

      expect(financial_partner.reload.status).to eq 'Partner - Financial'
      expect(financial_partner.pledge_amount).to eq 50
      expect(financial_partner.pledge_frequency).to eq 1
      expect(special_partner.reload.status).to eq 'Partner - Special'
    end
  end

  context '#merge_contacts' do
    it 'merges duplicate contacts by common name and donor number / address' do
      account_list = create(:account_list)
      donor = create(:donor_account)
      contact1 = create(:contact, name: 'John', account_list: account_list)
      contact2 = create(:contact, name: 'John', account_list: account_list)
      contact1.donor_accounts << donor
      contact2.donor_accounts << donor

      expect do
        account_list.merge_contacts
      end.to change(Contact, :count).by(-1)
    end
  end

  context '#currencies' do
    it 'gives the currencies of contacts, organizations and configured default' do
      account_list = create(:account_list, settings: { currency: 'EUR' })
      create(:contact, account_list: account_list, pledge_currency: 'GBP')
      user = create(:user)
      account_list.users << user
      org = create(:fake_org, default_currency_code: 'JPY')
      user.organization_accounts << create(:organization_account, organization: org)

      expect(account_list.currencies).to contain_exactly('EUR', 'GBP', 'JPY')
    end
  end

  context '#donations' do
    it 'shows no online org donations for account list with no designations' do
      online_org = create(:organization, api_class: 'Siebel')
      donor_account = create(:donor_account, organization: online_org)
      designation_account = create(:designation_account, organization: online_org)
      account_list = create(:account_list)
      contact = create(:contact, account_list: account_list)
      contact.donor_accounts << donor_account
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account)

      expect(account_list.donations).to be_empty
    end

    it 'shows donations for account list that has designations' do
      online_org = create(:organization, api_class: 'Siebel')
      donor_account = create(:donor_account, organization: online_org)
      designation_account = create(:designation_account, organization: online_org)
      account_list = create(:account_list)
      donation = create(:donation, donor_account: donor_account,
                                   designation_account: designation_account)
      contact = create(:contact, account_list: account_list)
      contact.donor_accounts << donor_account
      account_list.designation_accounts << designation_account

      expect(account_list.donations.to_a).to eq([donation])
    end

    it 'shows offline org donations for account with designations' do
      account_list = create(:account_list)
      contact = create(:contact, account_list: account_list)
      offline_org = create(:organization, api_class: 'OfflineOrg')
      donor_account = create(:donor_account, organization: offline_org)
      designation_account = create(:designation_account, organization: offline_org)
      designation_profile = create(:designation_profile, account_list: account_list)
      create(:designation_profile_account, designation_account: designation_account,
                                           designation_profile: designation_profile)
      donation = create(:donation, donor_account: donor_account,
                                   designation_account: designation_account)
      contact.donor_accounts << donor_account
      expect(account_list.donations.to_a).to eq([donation])
    end
  end
end
