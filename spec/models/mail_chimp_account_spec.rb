require 'spec_helper'

describe MailChimpAccount do
  let(:account) { MailChimpAccount.new(api_key: 'fake-us4') }
  let(:api_prefix) { 'https://apikey:fake-us4@us4.api.mailchimp.com/3.0' }
  let(:account_list) { create(:account_list) }
  let(:appeal) { create(:appeal, account_list: account_list) }

  it 'validates the format of an api key' do
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'DEFAULT__{8D2385FE-5B3A-4770-A399-1AF1A6436A00}')).not_to be_valid
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'jk234lkwjntlkj3n5lk3j3kj-us4')).to be_valid
  end

  before(:each) do
    account.account_list = account_list

    lists_response = {
      lists: [
        { id: '1e72b58b72', name: 'Test 1' },
        { id: '29a77ba541', name: 'Test 2' }
      ]
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(body: lists_response.to_json)
  end

  context '#lists' do
    it 'returns an array of lists' do
      expect(account.lists.map(&:id)).to eq %w(1e72b58b72 29a77ba541)
      expect(account.lists.map(&:name)).to eq ['Test 1', 'Test 2']
    end

    it 'works even if you call validate_key first' do
      account.validate_key

      expect(account.lists.map(&:name)).to eq ['Test 1', 'Test 2']
    end
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
    error = {
      title: 'API Key Invalid', status: 401,
      detail: "Your API key may be invalid, or you've attempted to access the wrong datacenter."
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(status: 401, body: error.to_json)
    account.active = true

    account.validate_key

    expect(account.active).to be false
    expect(account.validation_error).to match(/Your API key may be invalid/)
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

    context '#queue_log_sent_campaign' do
      it 'queues logging campaign if set to auto-log campaigns' do
        account.auto_log_campaigns = true
        expect do
          account.queue_log_sent_campaign('campaign1', 'subject')
        end.to change(MailChimpAccount.jobs, :size).by(1)
      end

      it 'does nothing if the mail chimp account not set to auto-log campaigns' do
        account.auto_log_campaigns = false
        expect do
          account.queue_log_sent_campaign('campaign1', 'subject')
        end.to_not change(MailChimpAccount.jobs, :size)
      end
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

    it 'queues import subscriber' do
      expect do
        account.queue_import_new_member('j@t.co')
      end.to change(MailChimpAccount.jobs, :size).by(1)
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

      it 'imports new subscribers' do
        import = double
        expect(MailChimpImport).to receive(:new).with(account) { import }
        expect(import).to receive(:import_members_by_emails).with(['j@t.co'])
        account.send(:import_new_member, 'j@t.co')
      end

      it 'does not unsubscribe the newly imported contacts' do
        account.primary_list_id = 'foo'

        expect(account).to receive(:setup_webhooks)
        expect(account).to receive(:add_status_groups)
        expect(account).to receive(:add_greeting_merge_variable)
        expect(account).to receive(:list_emails) { ['j@t.co'] }
        expect(account).to receive(:list_member_info) do
          [{ 'email_address' => 'j@t.co', 'merge_fields' => {},
             'status' => 'subscribed' }]
        end
        expect(account).to receive(:list_batch_subscribe)

        expect(account).to_not receive(:unsubscribe_list_batch)
        account.send(:export_to_primary_list)
      end

      it 'exports to a list and saves mail chimp member records' do
        account.primary_list_id = 'list1'
        account.save
        member_json = {
          status_if_new: 'subscribed', email_address: 'foo@example.com',
          merge_fields: { EMAIL: 'foo@example.com', FNAME: 'John', LNAME: 'Smith', GREETING: 'John' },
          language: 'fr',
          interests: { i1: true }
        }.to_json
        stub_request(:put, "#{api_prefix}/lists/list1/members/b48def645758b95537d4424c84d1a9ff")
          .with(body: member_json)
        account.grouping_id = 1
        account.status_interest_ids = { 'Partner - Financial' => 'i1' }
        contact = create(:contact, send_newsletter: 'Email', account_list: account_list,
                                   locale: 'fr')
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
    it 'raises an error to silently retry job on status 429 (too many requests)' do
      account.primary_list_id = 'list1'
      account.active = true
      detail = 'You have exceeded the limit of 10 simultaneous connections.'
      err = Gibbon::MailChimpError.new(detail, status_code: 429, detail: detail)
      expect(account).to receive(:sync_contacts).with(1).and_raise(err)
      expect do
        account.call_mailchimp(:sync_contacts, 1)
      end.to raise_error(LowerRetryWorker::RetryJobButNoRollbarError)
    end
  end

  context '#add_greeting_merge_variable' do
    before do
      account.primary_list_id = 'list1'
    end

    it 'does not add a greeting merge variable if it already exists' do
      check_merge_fields = stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
                           .to_return(body: { merge_fields: [{ name: 'Greeting', tag: 'GREETING' }] }.to_json)

      account.add_greeting_merge_variable(account.primary_list_id)

      expect(check_merge_fields).to have_been_made
    end

    it 'adds the greeting merge variable if it does not exist' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      create_merge_field = stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
                           .with(body: { tag: 'GREETING', name: 'Greeting', type: 'text' }.to_json)

      account.add_greeting_merge_variable(account.primary_list_id)

      expect(create_merge_field).to have_been_made
    end

    it 'does not raise an error if the greeting variable added after call to check for it' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(status: 400, body: {
          detail: 'A Merge Field with the tag "GREETING" already exists for this list.'
        }.to_json)

      expect { account.add_greeting_merge_variable(account.primary_list_id) }.to_not raise_error
    end

    it 'does not error on a 500 status but does notify Rollbar' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(status: 500, body: {
          detail: 'internal error has occurred during the processing of your request'
        }.to_json)
      expect(Rollbar).to receive(:error)

      expect { account.add_greeting_merge_variable(account.primary_list_id) }.to_not raise_error
    end
  end

  context '#setup_webhooks' do
    before do
      account.primary_list_id = 'list1'
    end

    def expect_webhook_created
      expect(SecureRandom).to receive(:hex).at_least(:once).and_return('abc123')
      hook_params = {
        url: 'https://mpdx.org/mail_chimp_webhook/abc123',
        events: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                  upemail: true, campaign: true },
        sources: { user: true, admin: true, api: false }
      }
      hook_created = stub_request(:post, "#{api_prefix}/lists/list1/webhooks").with(body: hook_params.to_json)

      yield

      expect(account.webhook_token).to eq('abc123')
      expect(hook_created).to have_been_requested
    end

    it 'creates a webhook if the webhook token is missing' do
      expect_webhook_created { account.setup_webhooks(account.primary_list_id) }
    end

    it 're-uses previously set webhook token when creating webhooks' do
      account.update(webhook_token: 'already_set_token')
      stub_request(:get, "#{api_prefix}/lists/list1/webhooks")
        .to_return(body: { webhooks: [] }.to_json)

      hook_params = {
        url: 'https://mpdx.org/mail_chimp_webhook/already_set_token',
        events: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                  upemail: true, campaign: true },
        sources: { user: true, admin: true, api: false }
      }
      hook_created = stub_request(:post, "#{api_prefix}/lists/list1/webhooks").with(body: hook_params.to_json)

      account.setup_webhooks('list1')

      expect(hook_created).to have_been_requested
    end

    it 'does not create a webhook if it already exists' do
      account.update(webhook_token: '111')
      stub_request(:get, "#{api_prefix}/lists/list1/webhooks")
        .to_return(body: {
          webhooks: [{ url: 'https://mpdx.org/mail_chimp_webhook/111' }]
        }.to_json)

      account.setup_webhooks(account.primary_list_id)
    end
  end

  context '#find_grouping' do
    it 'retrieves the list grouping based on grouping_id' do
      categories_response = {
        categories: [
          { list_id: '1e72b58b72', id: 'a2be97f1fe', title: 'Partner Status' }
        ]
      }
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories")
        .to_return(body: categories_response.to_json)
      account.grouping_id = 'a2be97f1fe'

      grouping = account.find_grouping('1e72b58b72')

      expect(grouping['title']).to eq 'Partner Status'
    end

    it 'retrieves the list grouping for Partner Status if no grouping set' do
      categories_response = {
        categories: [
          { list_id: '1e72b58b72', id: 'a2be97f1fe', title: 'Partner Status' }
        ]
      }
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories")
        .to_return(body: categories_response.to_json)

      grouping = account.find_grouping('1e72b58b72')

      expect(grouping['title']).to eq 'Partner Status'
      expect(grouping['id']).to eq 'a2be97f1fe'
    end
  end

  context '#add_status_groups' do
    it 'makes exsting status category hidden, adds status interest groups' do
      categories = [
        { list_id: '1e72b58b72', id: 'a2be97f1fe', title: 'Partner Status' }
      ]
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe")
                    .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)
      create_group = stub_request(:post, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe/interests")
                     .with(body: '{"name":"Partner - Special"}')

      account.add_status_groups('1e72b58b72', ['Partner - Special'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'does not error if mailchimp says interest already added' do
      categories = [
        { list_id: '1e72b58b72', id: 'a2be97f1fe', title: 'Partner Status' }
      ]
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe")
                    .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)
      create_group =
        stub_request(:post, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe/interests")
        .with(body: '{"name":"Partner - Special"}')
        .to_return(status: 400, body: {
          detail: 'Cannot add "Partner - Party" because it already exists on the list."'
        }.to_json)

      account.add_status_groups('1e72b58b72', ['Partner - Special'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'creates a new status category if none exists' do
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories")
        .to_return(body: { categories: [] }.to_json)
        .then.to_return(body: { categories: [
          { list_id: '1e72b58b72', id: 'a2be97f1fe', title: 'Partner Status' }
        ] }.to_json)
      create_category = stub_request(:post, "#{api_prefix}/lists/1e72b58b72/interest-categories/")
                        .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/1e72b58b72/interest-categories/a2be97f1fe/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)

      account.add_status_groups('1e72b58b72', [])

      expect(create_category).to have_been_made
    end
  end

  context '#unsubscribe_list_batch' do
    it 'unsubscribes a single member with a single API call' do
      member = create(:mail_chimp_member, mail_chimp_account: account,
                                          email: 'john@example.com')
      email_hash = 'd4c74594d841139328695756648b6bd6'
      delete_member = stub_request(:delete, "#{api_prefix}/lists/list1/members/#{email_hash}")

      account.unsubscribe_list_batch('list1', ['john@example.com'])

      expect(delete_member).to have_been_requested
      expect(MailChimpMember.find_by(id: member.id)).to be_nil
    end

    it 'does not error on a 404 status and still deletes member record' do
      create(:mail_chimp_member, mail_chimp_account: account, email: 'john@example.com')
      email_hash = 'd4c74594d841139328695756648b6bd6'
      delete_member = stub_request(:delete, "#{api_prefix}/lists/list1/members/#{email_hash}")
                      .to_return(status: 404)

      expect do
        account.unsubscribe_list_batch('list1', ['john@example.com'])
      end.to change(MailChimpMember, :count).by(-1)

      expect(delete_member).to have_been_requested
    end

    it 'unsubscribes several members with a batch API call' do
      emails = Array.new(3) { |i| "j#{i}@t.co" }
      emails.each { |e| create(:mail_chimp_member, mail_chimp_account: account, email: e) }
      batch_operations = [
        { method: 'DELETE', path: '/lists/list1/members/6779e6bef717b2ad54df04be61d3441c' },
        { method: 'DELETE', path: '/lists/list1/members/7f436bbb925adddaff9d1b85d053cf31' },
        { method: 'DELETE', path: '/lists/list1/members/75576f0fd15e52eca2b83b46ffff2273' }
      ]
      batch_delete = stub_request(:post, "#{api_prefix}/batches")
                     .with(body: { operations: batch_operations }.to_json)

      expect do
        account.unsubscribe_list_batch('list1', emails)
      end.to change(MailChimpMember, :count).by(-3)

      expect(batch_delete).to have_been_requested
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
      sent_to = emails.map { |email| { email_address: email } }
      stub_request(:get, "#{api_prefix}/reports/c1/sent-to?count=15000")
        .to_return(body: { sent_to: sent_to }.to_json)
    end
  end

  context '#batch_params' do
    it 'does not include interests for non-primary lists' do
      contact = build(:contact, status: 'Partner - Special', greeting: 'Hi')
      person = build(:person, first_name: 'John', last_name: 'Doe')
      contact.people << person
      email_address = build(:email_address, email: 'j@t.co', primary: true)
      person.primary_email_address = email_address
      account.grouping_id = '1a'
      account.status_interest_ids = { 'Partner - Special' => 'i1', 'Partner - Pray' => 'i2' }
      account.primary_list_id = 'primary_list'

      expect(account.batch_params([contact], 'not-primary-list').first)
        .to_not have_key(:interests)
    end
  end

  context '#create_member_records' do
    it 'works even if interests parameter is missing' do
      member_params = [
        {
          status_if_new: 'subscribed', email_address: 'j@t.co',
          merge_fields: { EMAIL: 'j@t.co', FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' }
        }
      ]
      account.primary_list_id = 'list1'
      account.save

      expect do
        account.create_member_records(member_params, 'list1')
      end.to change(MailChimpMember, :count).by(1)

      expect(MailChimpMember.last.list_id).to eq 'list1'
    end
  end

  context '#list_batch_subscribe' do
    it 'subscribes a single member with a single API call' do
      contact = build(:contact, status: 'Partner - Special', greeting: 'Hi')
      person = build(:person, first_name: 'John', last_name: 'Doe')
      contact.people << person
      email_address = build(:email_address, email: 'j@t.co', primary: true)
      person.primary_email_address = email_address
      account.grouping_id = '1a'
      account.status_interest_ids = { 'Partner - Special' => 'i1', 'Partner - Pray' => 'i2' }
      account.primary_list_id = 'list1'
      params = account.batch_params([contact], 'list1')
      member_params_json = {
        status_if_new: 'subscribed', email_address: 'j@t.co',
        merge_fields: { EMAIL: 'j@t.co', FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' },
        interests: { i1: true, i2: false }
      }.to_json
      subscribe_request =
        stub_request(:put, "#{api_prefix}/lists/list1/members/47f62523d9b40ad2176baf884072aca5")
        .with(body: member_params_json)

      account.list_batch_subscribe(id: 'list1', batch: params)

      expect(subscribe_request).to have_been_requested
    end

    it 'does not error if the subscribe request gives an invalid email err' do
      params = {
        status_if_new: 'subscribed', email_address: 'j@t.co',
        merge_fields: { EMAIL: 'j@t.co', FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' }
      }
      subscribe_request =
        stub_request(:put, "#{api_prefix}/lists/list1/members/47f62523d9b40ad2176baf884072aca5")
        .to_return(status: 400, body: {
          detail: 'The username portion of the email address is invalid'
        }.to_json)

      expect do
        account.list_batch_subscribe(id: 'list1', batch: [params])
      end.to_not raise_error

      expect(subscribe_request).to have_been_requested
    end

    it 'subscribes several members with a batch API call' do
      emails = Array.new(3) { |i| "j#{i}@t.co" }
      batch_params = emails.map do |email|
        { status_if_new: 'subscribed', email_address: email,
          merge_fields: { EMAIL: email, FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' },
          interests: { 'i1' => true } }
      end
      batch_operations = [
        { method: 'PUT', path: '/lists/list1/members/6779e6bef717b2ad54df04be61d3441c',
          body: '{"status_if_new":"subscribed","email_address":"j0@t.co",'\
          '"merge_fields":{"EMAIL":"j0@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},'\
          '"interests":{"i1":true}}' },
        { method: 'PUT', path: '/lists/list1/members/7f436bbb925adddaff9d1b85d053cf31',
          body: '{"status_if_new":"subscribed","email_address":"j1@t.co",'\
          '"merge_fields":{"EMAIL":"j1@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},'\
          '"interests":{"i1":true}}' },
        { method: 'PUT', path: '/lists/list1/members/75576f0fd15e52eca2b83b46ffff2273',
          body: '{"status_if_new":"subscribed","email_address":"j2@t.co",'\
          '"merge_fields":{"EMAIL":"j2@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},"interests":{"i1":true}}' }
      ]
      batch_subscribe = stub_request(:post, "#{api_prefix}/batches")
                        .with(body: { operations: batch_operations }.to_json)

      account.list_batch_subscribe(id: 'list1', batch: batch_params)

      expect(batch_subscribe).to have_been_requested
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

      stub_request(:get, "#{api_prefix}/lists/appeal_list1/members?count=100&offset=0")
        .to_return(body: {
          members: [{ email_address: 'foo@example.com', id: '1' }],
          total_items: 1
        }.to_json)
    end

    context '#export_appeal_contacts' do
      it 'will not export if primary list equals appeals list' do
        list_id = account.primary_list_id
        expect(account).to_not receive(:export_to_list)
        account.send(:export_appeal_contacts, [contact1.id, contact2.id], list_id, appeal.id)
      end

      it 'exports appeal contacts' do
        expect(account).to receive(:setup_webhooks).with('appeal_list1')
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
          .to eq([{ 'email_address' => 'foo@example.com', 'id' => '1' }])
      end
    end

    context '#list_emails' do
      it 'returns only the list emails' do
        expect(account.list_emails(list_id)).to eq ['foo@example.com']
      end
    end

    context '#list_member_info' do
      it 'retrieves the list member info' do
        data = [{ 'email_address' => 'foo@example.com', 'id' => '1' }]

        expect(account.list_member_info(list_id, ['foo@example.com'])).to eq data
      end

      it 'filters out member info that do not match given emails' do
        expect(account.list_member_info(list_id, ['not-foo@example.com'])).to be_empty
      end

      it 'retrieves member info by requesting multiple pages' do
        stub_request(:get, "#{api_prefix}/lists/appeal_list1/members?count=100&offset=0")
          .to_return(body: {
            members: [{ email_address: 'f1@t.co', id: '1', status: 'subscribed' }], total_items: 200
          }.to_json)
        stub_request(:get, "#{api_prefix}/lists/appeal_list1/members?count=100&offset=100")
          .to_return(body: { members: [{ email_address: 'f2@t.co', id: '2', status: 'subscribed' }] }.to_json)

        members_info = account.list_member_info(list_id, ['f1@t.co', 'f2@t.co'])

        expect(members_info.size).to eq 2
        expect(members_info.map { |m| m['email_address'] }).to eq ['f1@t.co', 'f2@t.co']
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

    it 'does nothing for invalid email address errors' do
      invalid_email_messages = [
        'j@t.co looks fake or invalid, please enter a real email address.',
        'The username portion of the email address is invalid (the portion before the @: or;vfc21)'
      ]

      invalid_email_messages.each do |message|
        expect do
          err = Gibbon::MailChimpError.new(message, status_code: 400, detail: message)
          account.handle_newsletter_mc_error(err)
        end.to_not raise_error
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
