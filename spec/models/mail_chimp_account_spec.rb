require 'spec_helper'

describe MailChimpAccount do
  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:account) { MailChimpAccount.new(api_key: 'fake-us4', primary_list_id: primary_list_id) }
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
        { id: primary_list_id, name: 'Test 1' },
        { id: primary_list_id_2, name: 'Test 2' }
      ]
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(body: lists_response.to_json)
  end

  context '#lists' do
    it 'returns an array of lists' do
      expect(account.lists.map(&:id)).to eq [primary_list_id, primary_list_id_2]
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
      account.primary_list_id = primary_list_id
      expect(account.lists_available_for_appeals.map(&:id)).to eq([primary_list_id_2])
    end
  end

  context '#lists_available_for_newsletters' do
    it 'returns all lists if no appeals list.' do
      expect(account.lists_available_for_newsletters.length).to eq(2)
    end

    it 'excludes the appeals list if specified' do
      account.mail_chimp_appeal_list = create(:mail_chimp_appeal_list, appeal_list_id: primary_list_id,
                                                                       appeal: appeal, mail_chimp_account: account)
      expect(account.lists_available_for_newsletters.map(&:id)).to eq([primary_list_id_2])
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
