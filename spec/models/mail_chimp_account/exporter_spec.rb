require 'spec_helper'

describe MailChimpAccount::Exporter do
  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:generic_group_id) { 'a2be97f1fe' }
  let(:account_list) { create(:account_list) }
  let(:account) { MailChimpAccount.create(api_key: 'fake-us4', primary_list_id: primary_list_id, account_list: account_list) }
  let(:api_prefix) { 'https://apikey:fake-us4@us4.api.mailchimp.com/3.0' }
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:export) { MailChimpAccount::Exporter.new(account) }
  let(:non_primary_export) { MailChimpAccount::Exporter.new(account, 'not-primary-list') }

  before do
    $rollout.activate(:mailchimp_tags_export)
  end

  before(:each) do
    lists_response = {
      lists: [
        { id: primary_list_id, name: 'Test 1' },
        { id: primary_list_id_2, name: 'Test 2' }
      ]
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(body: lists_response.to_json)
  end

  context 'when updating mailchimp' do
    context 'subscribing contacts' do
      it 'sets up the webhooks, clears the cached members and syncs contacts' do
        create(:mail_chimp_member, mail_chimp_account: account, list_id: 'not-primary-list')

        expect(non_primary_export).to receive(:setup_webhooks)
        import = double
        expect(MailChimpImport).to receive(:new) { import }
        expect(import).to receive(:import_contacts)
        sync = double
        expect(MailChimpSync).to receive(:new) { sync }
        expect(sync).to receive(:sync_contacts)

        expect do
          non_primary_export.send(:export_to_primary_list)
        end.to change(MailChimpMember, :count).by(-1)
      end

      it 'imports new subscribers' do
        import = double
        expect(MailChimpImport).to receive(:new).with(account) { import }
        expect(import).to receive(:import_members_by_emails).with(['j@t.co'])
        account.send(:import_new_member, 'j@t.co')
      end

      it 'does not unsubscribe the newly imported contacts' do
        expect_any_instance_of(MailChimpAccount::Exporter).to receive(:setup_webhooks)
        expect_any_instance_of(MailChimpAccount::Exporter).to receive(:add_status_groups)
        expect_any_instance_of(MailChimpAccount::Exporter).to receive(:add_tags_groups)
        expect_any_instance_of(MailChimpAccount::Exporter).to receive(:add_greeting_merge_variable)
        expect(account).to receive(:list_emails) { ['j@t.co'] }
        expect(account).to receive(:list_member_info) do
          [{ 'email_address' => 'j@t.co', 'merge_fields' => {},
             'status' => 'subscribed' }]
        end
        expect_any_instance_of(MailChimpAccount::Exporter).to receive(:list_batch_subscribe)

        expect(account).to_not receive(:unsubscribe_list_batch)
        export.send(:export_to_primary_list)
      end

      it 'exports to a list and saves mail chimp member records' do
        member_json = {
          status_if_new: 'subscribed', email_address: 'foo@example.com',
          merge_fields: { EMAIL: 'foo@example.com', FNAME: 'John', LNAME: 'Smith', GREETING: 'John' },
          language: 'fr',
          interests: { i1: true, i2: true, i3: true }
        }.to_json
        stub_request(:put, "#{api_prefix}/lists/#{primary_list_id}/members/b48def645758b95537d4424c84d1a9ff")
          .with(body: member_json)

        account.status_grouping_id = '1'
        account.status_interest_ids = { 'Partner - Financial' => 'i1' }
        account.tags_grouping_id = '2'
        account.tags_interest_ids = { 'one' => 'i2', 'two' => 'i3' }
        account.save

        contact = create(:contact, :with_tags, send_newsletter: 'Email', account_list: account_list, locale: 'fr')
        contact.people << create(:person, email: 'foo@example.com')

        expect(export).to receive(:add_status_groups)
        expect(export).to receive(:add_tags_groups)
        expect(export).to receive(:add_greeting_merge_variable)

        expect do
          export.send(:export_to_list, [contact])
        end.to change(account.mail_chimp_members, :count).by(1)

        member = account.mail_chimp_members.first
        expect(member.email).to eq 'foo@example.com'
        expect(member.status).to eq 'Partner - Financial'
        expect(member.tags).to eq %w(one two)
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

      export.add_greeting_merge_variable

      expect(check_merge_fields).to have_been_made
    end

    it 'adds the greeting merge variable if it does not exist' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      create_merge_field = stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
                           .with(body: { tag: 'GREETING', name: 'Greeting', type: 'text' }.to_json)

      export.add_greeting_merge_variable

      expect(create_merge_field).to have_been_made
    end

    it 'does not raise an error if the greeting variable added after call to check for it' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(status: 400, body: {
          detail: 'A Merge Field with the tag "GREETING" already exists for this list.'
        }.to_json)

      expect { export.add_greeting_merge_variable }.to_not raise_error
    end

    it 'does not error on a 500 status but does notify Rollbar' do
      stub_request(:get, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(body: { merge_fields: [] }.to_json)
      stub_request(:post, "#{api_prefix}/lists/list1/merge-fields")
        .to_return(status: 500, body: {
          detail: 'internal error has occurred during the processing of your request'
        }.to_json)
      expect(Rollbar).to receive(:error)

      expect { export.add_greeting_merge_variable }.to_not raise_error
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
      expect_webhook_created { export.setup_webhooks }
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

      export.setup_webhooks

      expect(hook_created).to have_been_requested
    end

    it 'does not create a webhook if it already exists' do
      account.update(webhook_token: '111')
      stub_request(:get, "#{api_prefix}/lists/list1/webhooks")
        .to_return(body: {
          webhooks: [{ url: 'https://mpdx.org/mail_chimp_webhook/111' }]
        }.to_json)

      export.setup_webhooks
    end
  end

  context '#find_status_grouping' do
    it 'retrieves the list grouping based on status_grouping_id' do
      categories_response = {
        categories: [
          { list_id: primary_list_id, id: generic_group_id, title: 'Partner Status' }
        ]
      }
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: categories_response.to_json)
      account.status_grouping_id = generic_group_id

      grouping = export.find_grouping(account.status_grouping_id, 'Partner Status')

      expect(grouping['title']).to eq 'Partner Status'
    end

    it 'retrieves the list grouping for Partner Status if no grouping set' do
      categories_response = {
        categories: [
          { list_id: primary_list_id, id: generic_group_id, title: 'Partner Status' }
        ]
      }
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: categories_response.to_json)

      grouping = export.find_grouping(nil, 'Partner Status')

      expect(grouping['title']).to eq 'Partner Status'
      expect(grouping['id']).to eq generic_group_id
    end
  end

  context '#add_status_groups' do
    before(:each) do
      account.status_grouping_id = generic_group_id
    end

    it 'makes exsting status category hidden, adds status interest groups' do
      categories = [
        { list_id: primary_list_id, id: generic_group_id, title: 'Partner Status' }
      ]
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}")
                    .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)
      create_group = stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
                     .with(body: '{"name":"Partner - Special"}')

      export.add_status_groups(['Partner - Special'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'does not error if mailchimp says interest already added' do
      categories = [
        { list_id: primary_list_id, id: generic_group_id, title: 'Partner Status' }
      ]
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}")
                    .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)
      create_group =
        stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .with(body: '{"name":"Partner - Special"}')
        .to_return(status: 400, body: {
          detail: 'Cannot add "Partner - Party" because it already exists on the list."'
        }.to_json)

      export.add_status_groups(['Partner - Special'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'creates a new status category if none exists' do
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: [] }.to_json)
        .then.to_return(body: { categories: [
          { list_id: primary_list_id, id: generic_group_id, title: 'Partner Status' }
        ] }.to_json)
      create_category = stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
                        .with(body: { title: 'Partner Status', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'Partner - Pray' }] }.to_json)
      account.status_grouping_id = nil

      export.add_status_groups([])

      expect(create_category).to have_been_made
    end
  end

  context '#add_tags_groups' do
    before(:each) do
      account.tags_grouping_id = generic_group_id
    end

    it 'makes exsting tags category hidden, adds tags interest groups' do
      categories = [
        { list_id: primary_list_id, id: generic_group_id, title: 'Tags' }
      ]
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}")
                    .with(body: { title: 'Tags', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'one' }] }.to_json)
      create_group = stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
                     .with(body: '{"name":"two"}')

      export.add_tags_groups(['two'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'does not error if mailchimp says interest already added' do
      categories = [
        { list_id: primary_list_id, id: generic_group_id, title: 'Tags' }
      ]
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: categories }.to_json)
      make_hidden = stub_request(:patch, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}")
                    .with(body: { title: 'Tags', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'one' }] }.to_json)
      create_group =
        stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .with(body: '{"name":"two"}')
        .to_return(status: 400, body: {
          detail: 'Cannot add "three" because it already exists on the list."'
        }.to_json)

      export.add_tags_groups(['two'])

      expect(make_hidden).to have_been_made
      expect(create_group).to have_been_made
    end

    it 'creates a new tags category if none exists' do
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
        .to_return(body: { categories: [] }.to_json)
        .then.to_return(body: { categories: [
          { list_id: primary_list_id, id: generic_group_id, title: 'Tags' }
        ] }.to_json)
      create_category = stub_request(:post, "#{api_prefix}/lists/#{primary_list_id}/interest-categories")
                        .with(body: { title: 'Tags', type: 'hidden' }.to_json)
      stub_request(:get, "#{api_prefix}/lists/#{primary_list_id}/interest-categories/#{generic_group_id}/interests")
        .to_return(body: { interests: [{ id: 'i1', name: 'one' }] }.to_json)
      account.tags_grouping_id = nil

      export.add_tags_groups([])

      expect(create_category).to have_been_made
    end
  end

  context '#batch_params' do
    it 'does include interests for non-primary lists' do
      contact = create(:contact, :with_tags, status: 'Partner - Special', greeting: 'Hi')
      person = create(:person, first_name: 'John', last_name: 'Doe')
      contact.people << person
      email_address = create(:email_address, email: 'j@t.co', primary: true)
      person.primary_email_address = email_address
      account.status_grouping_id = '1a'
      account.status_interest_ids = { 'Partner - Special' => 'i1', 'Partner - Pray' => 'i2' }
      account.tags_grouping_id = '2a'
      account.tags_interest_ids = { 'one' => 'i3', 'two' => 'i4' }

      expect(non_primary_export.batch_params([contact]).first)
        .to have_key(:interests)
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
        export.create_member_records(member_params)
      end.to change(MailChimpMember, :count).by(1)

      expect(MailChimpMember.last.list_id).to eq 'list1'
    end
  end

  context '#list_batch_subscribe' do
    it 'subscribes a single member with a single API call' do
      contact = create(:contact, :with_tags, status: 'Partner - Special', greeting: 'Hi')
      person = create(:person, first_name: 'John', last_name: 'Doe')
      contact.people << person
      email_address = create(:email_address, email: 'j@t.co', primary: true)
      person.primary_email_address = email_address
      account.status_grouping_id = '1a'
      account.status_interest_ids = { 'Partner - Special' => 'i1', 'Partner - Pray' => 'i2' }
      account.tags_grouping_id = '2a'
      account.tags_interest_ids = { 'one' => 'i3', 'two' => 'i4' }
      params = export.batch_params([contact])
      member_params_json = {
        status_if_new: 'subscribed', email_address: 'j@t.co',
        merge_fields: { EMAIL: 'j@t.co', FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' },
        interests: { i1: true, i2: false, i3: true, i4: true }
      }.to_json
      subscribe_request =
        stub_request(:put, "#{api_prefix}/lists/#{primary_list_id}/members/47f62523d9b40ad2176baf884072aca5")
        .with(body: member_params_json)

      export.list_batch_subscribe(params)

      expect(subscribe_request).to have_been_requested
    end

    it 'does not error if the subscribe request gives an invalid email err' do
      params = {
        status_if_new: 'subscribed', email_address: 'j@t.co',
        merge_fields: { EMAIL: 'j@t.co', FNAME: 'John', LNAME: 'Doe', GREETING: 'Hi' }
      }
      subscribe_request =
        stub_request(:put, "#{api_prefix}/lists/#{primary_list_id}/members/47f62523d9b40ad2176baf884072aca5")
        .to_return(status: 400, body: {
          detail: 'The username portion of the email address is invalid'
        }.to_json)

      expect do
        export.list_batch_subscribe([params])
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
        { method: 'PUT', path: "/lists/#{primary_list_id}/members/6779e6bef717b2ad54df04be61d3441c",
          body: '{"status_if_new":"subscribed","email_address":"j0@t.co",'\
          '"merge_fields":{"EMAIL":"j0@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},'\
          '"interests":{"i1":true}}' },
        { method: 'PUT', path: "/lists/#{primary_list_id}/members/7f436bbb925adddaff9d1b85d053cf31",
          body: '{"status_if_new":"subscribed","email_address":"j1@t.co",'\
          '"merge_fields":{"EMAIL":"j1@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},'\
          '"interests":{"i1":true}}' },
        { method: 'PUT', path: "/lists/#{primary_list_id}/members/75576f0fd15e52eca2b83b46ffff2273",
          body: '{"status_if_new":"subscribed","email_address":"j2@t.co",'\
          '"merge_fields":{"EMAIL":"j2@t.co","FNAME":"John","LNAME":"Doe","GREETING":"Hi"},"interests":{"i1":true}}' }
      ]
      batch_subscribe = stub_request(:post, "#{api_prefix}/batches")
                        .with(body: { operations: batch_operations }.to_json)

      export.list_batch_subscribe(batch_params)

      expect(batch_subscribe).to have_been_requested
    end
  end

  describe 'mail chimp appeal methods' do
    let(:contact1) { create(:contact) }
    let(:contact2) { create(:contact) }
    let(:list_id) { 'appeal_list1' }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:appeal_export) { MailChimpAccount::Exporter.new(account, list_id) }

    before do
      contact1.people << create(:person, email: 'foo@example.com')
      contact2.people << create(:person, email: 'foo2@example.com')

      stub_request(:get, "#{api_prefix}/lists/#{list_id}/members?count=100&offset=0")
        .to_return(body: {
          members: [{ email_address: 'foo@example.com', id: '1' }],
          total_items: 1
        }.to_json)
    end

    context '#export_appeal_contacts' do
      it 'will not export if primary list equals appeals list' do
        account.primary_list_id = list_id
        expect(export).to_not receive(:export_to_list)
        appeal_export.send(:export_appeal_contacts, [contact1.id, contact2.id], appeal.id)
      end

      it 'exports appeal contacts' do
        expect(appeal_export).to receive(:setup_webhooks)
        expect(account).to receive(:contacts_with_email_addresses)
          .with([contact1.id, contact2.id]) { [contact2] }
        expect(appeal_export).to receive(:compare_and_unsubscribe).with([contact2])
        expect(appeal_export).to receive(:export_to_list).with([contact2])
        expect(appeal_export).to receive(:save_appeal_list_info)
        appeal_export.send(:export_appeal_contacts, [contact1.id, contact2.id], appeal.id)
      end
    end

    context '#compare_and_unsubscribe' do
      it 'does not unsubscribe when all members are passed in' do
        expect(account).to_not receive(:unsubscribe_list_batch)
        appeal_export.send(:compare_and_unsubscribe, [contact1])
      end

      it 'compares and unsubscribe contacts not passed in' do
        expect(account).to receive(:unsubscribe_list_batch).with(list_id, ['foo@example.com'])
        appeal_export.send(:compare_and_unsubscribe, [])
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
        account.mail_chimp_appeal_list = create(:mail_chimp_appeal_list, appeal_list_id: primary_list_id,
                                                                         appeal_id: appeal.id, mail_chimp_account: account)
        expect do
          non_primary_export.send(:save_appeal_list_info, appeal2.id)
        end.to_not change(MailChimpAppealList, :count)
        account.mail_chimp_appeal_list.reload
        expect(account.mail_chimp_appeal_list.appeal_list_id).to eq('not-primary-list')
        expect(account.mail_chimp_appeal_list.appeal.id).to eq(appeal2.id)
      end

      it 'creates a new mail chimp appeal list if not existing yet' do
        non_primary_export.send(:save_appeal_list_info, appeal2.id)
        expect(account.mail_chimp_appeal_list.appeal_list_id).to eq('not-primary-list')
        expect(account.mail_chimp_appeal_list.appeal.id).to eq(appeal2.id)
      end
    end
  end
end
