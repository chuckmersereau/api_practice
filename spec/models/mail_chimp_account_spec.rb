require 'spec_helper'

describe MailChimpAccount do
  let(:account) { MailChimpAccount.new(api_key: 'fake-us4') }
  let(:account_list) { create(:account_list) }
  let(:appeal) { create(:appeal, account_list: account_list) }

  it 'validates the format of an api key' do
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'DEFAULT__{8D2385FE-5B3A-4770-A399-1AF1A6436A00}')).not_to be_valid
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'jk234lkwjntlkj3n5lk3j3kj-us4')).to be_valid
  end

  before(:each) do
    account.account_list = account_list

    stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=lists')
      .with(body: '%7B%22apikey%22%3A%22fake-us4%22%7D')
      .to_return(body: '{"total":2,"data":['\
        '{"id":"1e72b58b72","web_id":97593,"name":"MPDX","date_created":"2012-10-09 13:50:12","email_type_option":false,"use_awesomebar":true,'\
        '"default_from_name":"MPDX","default_from_email":"support@mpdx.org","default_subject":"","default_language":"en","list_rating":3,'\
        '"subscribe_url_short":"http:\/\/eepurl.com\/qnY35",'\
        '"subscribe_url_long":"http:\/\/26am.us4.list-manage1.com\/subscribe?u=720971c5830c5228bdf461524&id=1e72b58b72",'\
        '"beamer_address":"NzIwOTcxYzU4MzBjNTIyOGJkZjQ2MTUyNC1iYmNlYzBkNS05ZDhlLTQ5NDctYTg1OC00ZjQzYTAzOGI3ZGM=@campaigns.mailchimp.com","visibility":"pub",'\
        '"stats":{"member_count":159,"unsubscribe_count":0,"cleaned_count":0,"member_count_since_send":159,"unsubscribe_count_since_send":0,'\
        '"cleaned_count_since_send":0,"campaign_count":0,"grouping_count":1,"group_count":4,"merge_var_count":2,"avg_sub_rate":null,"avg_unsub_rate":null,'\
        '"target_sub_rate":null,"open_rate":null,"click_rate":null},"modules":[]},'\
        '{"id":"29a77ba541","web_id":97493,"name":"Newsletter","date_created":"2012-10-09 00:32:44","email_type_option":true,"use_awesomebar":true,'\
        '"default_from_name":"Josh Starcher","default_from_email":"josh.starcher@cru.org","default_subject":"","default_language":"en","list_rating":0,'\
        '"subscribe_url_short":"http:\/\/eepurl.com\/qmAWn",'\
        '"subscribe_url_long":"http:\/\/26am.us4.list-manage.com\/subscribe?u=720971c5830c5228bdf461524&id=29a77ba541",'\
        '"beamer_address":"NzIwOTcxYzU4MzBjNTIyOGJkZjQ2MTUyNC02ZmZiZDJhOS0zNWFmLTQ1YzQtOWE0ZC1iOTZhMmRlMTQ0ZDc=@campaigns.mailchimp.com","visibility":"pub",'\
        '"stats":{"member_count":75,"unsubscribe_count":0,"cleaned_count":0,"member_count_since_send":75,"unsubscribe_count_since_send":0,'\
        '"cleaned_count_since_send":0,"campaign_count":0,"grouping_count":1,"group_count":3,"merge_var_count":2,"avg_sub_rate":null,"avg_unsub_rate":null,'\
        '"target_sub_rate":null,"open_rate":null,"click_rate":null},"modules":[]}]}')
  end

  it 'returns an array of lists' do
    expect(account.lists.length).to eq(2)
  end

  context '#lists_available_for_appeals' do
    it 'returns an available lists for appeal. the primary is excluded' do
      # list id from above stub
      account.primary_list_id = '1e72b58b72'
      expect(account.lists_available_for_appeals.map(&:id)).to eq(['29a77ba541'])
    end
  end

  context '#lists_available_for_newsletters' do
    it 'returns all lists if no appeals list.' do
      expect(account.lists_available_for_newsletters.length).to eq(2)
    end

    it 'excludes the appeals list if specified' do
      account.mail_chimp_appeal_list = create(:mail_chimp_appeal_list, appeal_list_id: '1e72b58b72',
                                                                       appeal: appeal, mail_chimp_account: account)
      expect(account.lists_available_for_newsletters.map(&:id)).to eq(['29a77ba541'])
    end
  end

  it 'finds a list by list_id' do
    allow(account).to receive(:lists).and_return([OpenStruct.new(id: 1, name: 'foo')])
    expect(account.list(1).name).to eq('foo')
  end

  it 'finds the primary list' do
    allow(account).to receive(:lists).and_return([OpenStruct.new(id: 1, name: 'foo')])
    account.primary_list_id = 1
    expect(account.primary_list.name).to eq('foo')
  end

  it 'deactivates the account if the api key is invalid' do
    stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=lists')
      .with(body: '%7B%22apikey%22%3A%22fake-us4%22%7D')
      .to_return(body: '{"error":"Invalid Mailchimp API Key: fake-us4","code":104}')
    account.active = true
    account.validate_key
    expect(account.active).to be false
    expect(account.validation_error).to match(/Invalid Mailchimp API Key: fake-us4/)
  end

  it 'activates the account if the api key is valid' do
    account.active = false
    account.validate_key
    expect(account.active).to eq(true)
  end

  describe 'queueing methods' do
    before do
      ResqueSpec.reset!
      account.save!
    end

    it 'queues subscribe_contacts' do
      expect(account).to receive(:async)
        .with(:call_mailchimp, :export_to_primary_list)
      account.queue_export_to_primary_list
    end

    it 'queues export_appeal_contacts' do
      contact = create(:contact)
      expect do
        account.queue_export_appeal_contacts(contact, 'list1', appeal.id)
      end.to change(MailChimpAccount.jobs, :size).by(1)
    end

    it 'queues log sync campaign' do
      expect do
        account.queue_log_sent_campaign('campaign1', 'subject')
      end.to change(MailChimpAccount.jobs, :size).by(1)
    end

    it 'queues sync contacts' do
      expect do
        account.queue_sync_contacts(1)
      end.to change(MailChimpAccount.jobs, :size).by(1)
    end

    it 'does not queue sync if importing' do
      account.update(importing: true)
      expect do
        account.queue_sync_contacts(1)
      end.to_not change(MailChimpAccount.jobs, :size)
    end
  end

  describe 'callbacks' do
    it 'queues export if primary list changed' do
      expect(account).to receive(:queue_export_to_primary_list).and_return(true)
      account.primary_list_id = 'foo'
      account.save
    end
  end

  context 'when updating mailchimp' do
    context 'subscribing contacts' do
      it 'sets up the webhooks, clears the cached members and syncs contacts' do
        account.primary_list_id = 'foo'
        create(:mail_chimp_member, mail_chimp_account: account, list_id: 'foo')

        expect(account).to receive(:setup_webhooks)
        import = double
        expect(MailChimpImport).to receive(:new) { import }
        expect(import).to receive(:import_contacts)
        sync = double
        expect(MailChimpSync).to receive(:new) { sync }
        expect(sync).to receive(:sync_contacts)

        expect do
          account.send(:export_to_primary_list)
        end.to change(MailChimpMember, :count).by(-1)
      end

      it 'exports to a list and saves mail chimp member records' do
        account.primary_list_id = 'list1'
        account.save

        stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=listBatchSubscribe')
          .with(body: '%7B%22apikey%22%3A%22fake-us4%22%2C%22id%22%3A%22list1%22%2C%22'\
            'batch%22%3A%5B%7B%22EMAIL%22%3A%22foo%40example.com%22%2C%22'\
            'FNAME%22%3A%22John%22%2C%22LNAME%22%3A%22Smith%22%2C%22GREETING%22%3A%22John%22%2C%22'\
            'GROUPINGS%22%3A%5B%7B%22id%22%3A1%2C%22groups%22%3A%22Partner+-+Financial%22%7D%5D%7D%5D%2C%22'\
            'update_existing%22%3Atrue%2C%22double_optin%22%3Afalse%2C%22send_welcome%22%3Afalse%2C%22'\
            'replace_interests%22%3Atrue%7D')
          .to_return(status: 200, body: '', headers: {})

        account.grouping_id = 1

        contact = create(:contact, send_newsletter: 'Email', account_list: account_list)
        contact.people << create(:person, email: 'foo@example.com')

        expect(account).to receive(:add_status_groups)
        expect(account).to receive(:add_greeting_merge_variable)
        expect do
          account.send(:export_to_list, account.primary_list_id, [contact])
        end.to change(account.mail_chimp_members, :count).by(1)
        member = account.mail_chimp_members.first
        expect(member.email).to eq 'foo@example.com'
        expect(member.status).to eq 'Partner - Financial'
        expect(member.greeting).to eq 'John'
        expect(member.first_name).to eq 'John'
        expect(member.last_name).to eq 'Smith'
      end

      context 'adding status groups' do
        before do
          @gb = double
          allow(account).to receive(:gb).and_return(@gb)
        end

        it 'adds groups to an existing grouping' do
          account.grouping_id = 1

          list_id = 'foo'

          expect(@gb).to receive(:list_interest_groupings).with(id: list_id)
            .and_return([{ 'id' => 1, 'name' => 'Partner Status', 'groups' => [] }])

          expect(@gb).to receive(:list_interest_grouping_update)
            .with(grouping_id: 1, name: 'type', value: 'hidden')

          expect(@gb).to receive(:list_interest_group_add)
            .with(id: 'foo', group_name: 'Partner - Pray', grouping_id: 1)

          account.send(:add_status_groups, list_id, ['Partner - Pray'])
        end

        it 'creates a new grouping if none exists' do
          list_id = 'foo'

          expect(@gb).to receive(:list_interest_groupings).with(id: list_id).and_return([])

          expect(@gb).to receive(:list_interest_grouping_add).with(id: 'foo', name: 'Partner Status', type: 'hidden', groups: ['Partner - Pray'])

          expect(@gb).to receive(:list_interest_groupings).with(id: list_id).and_return([{ 'id' => 1, 'name' => 'Partner Status', 'groups' => [] }])

          expect(@gb).to receive(:list_interest_group_add).with(id: 'foo', group_name: 'Partner - Pray', grouping_id: 1)

          account.send(:add_status_groups, list_id, ['Partner - Pray'])
        end
      end
    end

    describe 'filtering contacts with email and whether on letter' do
      let(:contact) do
        create(:contact, name: 'John Smith', send_newsletter: 'Email', account_list: account_list)
      end
      let(:person) { create(:person) }

      before do
        person.email_address = { email: 'foo@example.com', primary: true }
        person.save
        contact.people << person
      end

      context '#contacts_with_email_addresses' do
        it 'returns a contact with valid email on newsletter' do
          expect(account.contacts_with_email_addresses(nil).to_a).to eq [contact]
        end

        it 'returns nothing when person has no email address' do
          person.email_addresses.first.destroy
          expect(account.contacts_with_email_addresses(nil).to_a).to be_empty
        end

        it 'excludes contacts with historic email addresses' do
          person.email_addresses.first.update_column(:historic, true)
          expect(account.contacts_with_email_addresses(nil).to_a).to be_empty
        end

        describe 'it excludes people from the loaded contact.people association if: ' do
          let(:excluded_person) { create(:person) }
          before do
            excluded_person.email_address = { email: 'foo2@example.com', primary: true }
            excluded_person.save
            contact.people << excluded_person
          end

          it 'has no email address' do
            excluded_person.email_addresses.first.destroy
            expect_person_excluded
          end
          it 'has only a non-primary email' do
            expect(excluded_person.email_addresses.count).to eq 1
            excluded_person.email_addresses.first.update_column(:primary, false)
            expect_person_excluded
          end
          it 'has a historic email' do
            excluded_person.email_addresses.first.update_column(:historic, true)
            expect_person_excluded
          end

          def expect_person_excluded
            contact = account.contacts_with_email_addresses(nil).first
            expect(contact.people.size).to eq(1)
            expect(contact.people).to include person
            expect(contact.people).to_not include excluded_person
          end
        end

        it 'scopes the contacts to the passed in ids if specified' do
          expect(account.contacts_with_email_addresses([contact.id + 1])).to be_empty
        end
      end

      context '#newsletter_contacts_with_emails' do
        it 'excludes people not on the email newsletter' do
          contact.update(send_newsletter: 'Physical')
          expect(account.newsletter_contacts_with_emails(nil).to_a).to be_empty
        end

        it 'excludes a person from the loaded contact association if opted-out' do
          opt_out_person = create(:person, optout_enewsletter: true)
          opt_out_person.email_address = { email: 'foo2@example.com', primary: true }
          opt_out_person.save
          contact.people << opt_out_person
          opt_out_person.update(optout_enewsletter: true)
          contacts = account.newsletter_contacts_with_emails(nil)
          expect(contacts.first.people).to include(person)
          expect(contacts.first.people).to_not include(opt_out_person)
        end
      end
    end
  end

  context '#call_mailchimp' do
    it 'raises an error to silently retry the job if it gets error code -50 (too many connections)' do
      account.primary_list_id = 'list1'
      account.active = true
      msg = 'MailChimp API Error: No more than 10 simultaneous connections allowed. (code -50)'
      expect(account).to receive(:sync_contacts).with(1).and_raise(Gibbon::MailChimpError.new(msg))
      expect do
        account.call_mailchimp(:sync_contacts, 1)
      end.to raise_error(LowerRetryWorker::RetryJobButNoAirbrakeError)
    end
  end

  context '#add_greeting_merge_variable' do
    before do
      account.primary_list_id = 'list1'
    end

    it 'does not add a greeting merge variable if it already exists' do
      merge_vars = [
        { 'name' => 'Greeting', 'req' => false, 'field_type' => 'text', 'public' => true, 'show' => true,
          'order' => '5', 'default' => '', 'helptext' => '', 'size' => '25', 'tag' => 'GREETING', 'id' => 3 }
      ]
      expect(account.gb).to receive(:list_merge_vars).with(id: 'list1').and_return(merge_vars)
      expect(account.gb).to_not receive(:list_merge_var_add)
      account.add_greeting_merge_variable(account.primary_list_id)
    end

    it 'adds the greeting merge variable if it does not exist' do
      expect(account.gb).to receive(:list_merge_vars).with(id: 'list1').and_return([])
      expect(account.gb).to receive(:list_merge_var_add).with(id: 'list1', tag: 'GREETING', name: 'Greeting')
      account.add_greeting_merge_variable(account.primary_list_id)
    end

    it 'does not raise an error if the greeting variable added after call to check for it' do
      expect(account.gb).to receive(:list_merge_vars).with(id: 'list1').and_return([])

      msg = 'MailChimp API Error: A Merge Field with the tag "GREETING" already exists for this list. (code 254)'
      expect(account.gb).to receive(:list_merge_var_add).with(id: 'list1', tag: 'GREETING', name: 'Greeting')
        .and_raise(Gibbon::MailChimpError.new(msg))

      expect { account.add_greeting_merge_variable(account.primary_list_id) }.to_not raise_error
    end
  end

  context '#setup_webhooks' do
    before do
      allow($rollout).to receive(:active?).with(:mailchimp_webhooks, account_list)
        .at_least(:once).and_return(true)
      account.primary_list_id = 'list1'
    end

    def expect_webhook_created
      expect(SecureRandom).to receive(:hex).at_least(:once).and_return('abc123')
      hook_params = {
        id: 'list1', url: 'https://mpdx.org/mail_chimp_webhook/abc123',
        actions: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                   upemail: true, campaign: true },
        sources: { user: true, admin: true, api: false }
      }
      expect(account.gb).to receive(:list_webhook_add).with(hook_params)
      yield
      expect(account.webhook_token).to eq('abc123')
    end

    it 'creates a webhook if the webhook token is missing' do
      expect_webhook_created { account.setup_webhooks }
    end

    it 'creates a webhook if the webhook token is missing' do
      account.update(webhook_token: 'old')
      expect(account.gb).to receive(:list_webhooks).and_return([])
      expect_webhook_created { account.setup_webhooks }
    end

    it 'does not create a webhook if it already exists' do
      account.update(webhook_token: '111')
      expect(account.gb).to receive(:list_webhooks)
        .and_return([{ 'url' => 'https://mpdx.org/mail_chimp_webhook/111' }])
      expect(account.gb).to_not receive(:list_webhook_add)
      account.setup_webhooks
    end
  end

  context '#unsubscribe_list_batch' do
    it 'unsubscribes members and destroys their related records' do
      stub = stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=listBatchUnsubscribe')
             .with(body: '%7B%22apikey%22%3A%22fake-us4%22%2C%22id%22%3A%22list1%22%2C%22'\
             'emails%22%3A%22john%40example.com%22%2C%22delete_member%22%3Atrue%2C%22'\
             'send_goodbye%22%3Afalse%2C%22send_notify%22%3Afalse%7D')
      member = create(:mail_chimp_member, mail_chimp_account: account)
      account.unsubscribe_list_batch('list1', 'john@example.com')
      expect(stub).to have_been_requested
      expect(MailChimpMember.find_by(id: member.id)).to be_nil
    end
  end

  context '#log_sent_campaign' do
    let(:contact) { create(:contact, account_list: account_list) }
    before do
      account.account_list = account_list
      contact.people << create(:person_with_email)
    end

    it 'adds activity records to the contacts who received the campaign' do
      stub_campaign_members('john@example.com')
      expect do
        account.log_sent_campaign('c1', 'subject')
      end.to change(contact.activities, :count).by(1)

      activity = contact.activities.last
      expect(activity.account_list).to eq account_list
      expect(activity.subject).to eq 'MailChimp: subject'
      expect(activity.completed).to be true
      expect(activity.type).to eq 'Task'
      expect(activity.start_at).to be_within(2.seconds).of(Time.now)
      expect(activity.completed_at).to be_within(2.seconds).of(Time.now)
      expect(activity.activity_type).to eq 'Email'
      expect(activity.result).to eq 'Completed'
      expect(activity.source).to eq 'mailchimp'
    end

    it 'only logs a single activity if a contact has multiple matching people' do
      person2 = create(:person_with_email)
      person2.email_addresses.first.update(email: 'jane@example.com')
      contact.people << person2
      stub_campaign_members('john@example.com', 'jane@example.com')

      expect do
        account.log_sent_campaign('c1', 'subject')
      end.to change(contact.activities, :count).by(1)
    end

    def stub_campaign_members(*emails)
      expect(account.gb).to receive(:campaign_members).with(cid: 'c1', status: 'sent') do
        { 'data' => emails.map { |email| { 'email' => email } } }
      end
    end
  end

  describe 'mail chimp appeal methods' do
    let(:contact1) { create(:contact) }
    let(:contact2) { create(:contact) }
    let(:list_id) { 'appeal_list1' }
    let(:appeal) { create(:appeal, account_list: account_list) }

    before do
      contact1.people << create(:person, email: 'foo@example.com')
      contact2.people << create(:person, email: 'foo2@example.com')
      account.primary_list_id = 'list1'

      stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=listMembers')
        .with(body: '%7B%22apikey%22%3A%22fake-us4%22%2C%22id%22%3A%22appeal_list1%22%2C%22limit%22%3A15000%7D')
        .to_return(body: '{"total":1, "data":[{"email":"foo@example.com", "timestamp":"2015-07-31 14:39:19"}]}')
    end

    context '#export_appeal_contacts' do
      it 'will not export if primary list equals appeals list' do
        list_id = account.primary_list_id
        expect(account).to_not receive(:export_to_list)
        account.send(:export_appeal_contacts, [contact1.id, contact2.id], list_id, appeal.id)
      end

      it 'exports appeal contacts' do
        expect(account).to receive(:contacts_with_email_addresses)
          .with([contact1.id, contact2.id]) { [contact2] }
        expect(account).to receive(:compare_and_unsubscribe).with([contact2], 'appeal_list1')
        expect(account).to receive(:export_to_list).with('appeal_list1', [contact2])
        expect(account).to receive(:save_appeal_list_info)
        account.send(:export_appeal_contacts, [contact1.id, contact2.id], list_id, appeal.id)
      end
    end

    context '#compare_and_unsubscribe' do
      it 'does not unsubscribe when all members are passed in' do
        expect(account).to_not receive(:unsubscribe_list_batch).with('appeal_list1', [])
        account.send(:compare_and_unsubscribe, [contact1], list_id)
      end

      it 'compares and unsubscribe contacts not passed in' do
        expect(account).to receive(:unsubscribe_list_batch).with('appeal_list1', ['foo@example.com'])
        account.send(:compare_and_unsubscribe, [], list_id)
      end
    end

    context '#list_members' do
      it 'returns members of a list, specifically emails' do
        expect(account.send(:list_members, list_id))
          .to eq([{ 'email' => 'foo@example.com', 'timestamp' => '2015-07-31 14:39:19' }])
      end
    end

    context '#list_emails' do
      it 'returns only the list emails' do
        expect(account.list_emails(list_id)).to eq ['foo@example.com']
      end
    end

    context '#list_member_info' do
      it 'retrieves the list member info' do
        response = '{"data":[{"email":"foo@example.com","merges":{"FNAME":"Joe"}}]}'
        data = [{ 'email' => 'foo@example.com', 'merges' => { 'FNAME' => 'Joe' } }]
        stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=listMemberInfo')
          .with(body: '%7B%22apikey%22%3A%22fake-us4%22%2C%22id%22%3A%22'\
                      'appeal_list1%22%2C%22email_address%22%3A%5B%22'\
                      'foo%40example.com%22%5D%7D')
          .and_return(body: response)
        expect(account.list_member_info(list_id, ['foo@example.com'])).to eq data
      end

      it 'makes multiple batches of 50 for lots of emails' do
        url = 'https://us4.api.mailchimp.com/1.3/?method=listMemberInfo'
        data = Array.new(50, merges: { FNAME: 'Joe' })
        stub = stub_request(:post, url).and_return(body: { data: data }.to_json)

        expect(account.list_member_info(list_id, Array.new(100, 'j@example.com')))
          .to eq Array.new(100, 'merges' => { 'FNAME' => 'Joe' })
        expect(stub).to have_been_made.twice
      end
    end

    context '#save_appeal_list_info' do
      let(:appeal2) { create(:appeal) }

      it 'updates existing appeal list info' do
        account.mail_chimp_appeal_list = create(:mail_chimp_appeal_list, appeal_list_id: '1e72b58b72',
                                                                         appeal_id: appeal.id, mail_chimp_account: account)
        expect do
          account.send(:save_appeal_list_info, 'newlist', appeal2.id)
        end.to_not change(MailChimpAppealList, :count)
        account.mail_chimp_appeal_list.reload
        expect(account.mail_chimp_appeal_list.appeal_list_id).to eq('newlist')
        expect(account.mail_chimp_appeal_list.appeal.id).to eq(appeal2.id)
      end

      it 'creates a new mail chimp appeal list if not existing yet' do
        account.send(:save_appeal_list_info, 'newlist', appeal2.id)
        expect(account.mail_chimp_appeal_list.appeal_list_id).to eq('newlist')
        expect(account.mail_chimp_appeal_list.appeal.id).to eq(appeal2.id)
      end
    end
  end

  context '#handle_newsletter_mc_error' do
    it 'sets the primary_list_id to nil on a code 200 (no list) error' do
      account.save
      msg = 'Invalid MailChimp List ID (code 200)'
      account.handle_newsletter_mc_error(Gibbon::MailChimpError.new(msg))
      expect(account.reload.primary_list_id).to be_nil
    end

    it 'notifies user and clears primary_list_id if required merge field missing' do
      account.save
      msg = 'MMERGE3 must be provided - Please enter a value (code 250)'

      email = double
      expect(AccountMailer).to receive(:mailchimp_required_merge_field)
        .with(account_list) { email }
      expect(email).to receive(:deliver)

      account.handle_newsletter_mc_error(Gibbon::MailChimpError.new(msg))
      expect(account.reload.primary_list_id).to be_nil
    end

    it 'does nothing for specified benign error codes' do
      [502, 220, 214].each do |code|
        msg = "Error (code #{code})"
        account.handle_newsletter_mc_error(Gibbon::MailChimpError.new(msg))
      end
    end

    it 're-raises other mail chimp errors' do
      expect do
        msg = 'other err'
        account.handle_newsletter_mc_error(Gibbon::MailChimpError.new(msg))
      end.to raise_error(Gibbon::MailChimpError)
    end
  end
end
