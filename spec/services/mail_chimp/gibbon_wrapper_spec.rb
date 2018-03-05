require 'rails_helper'

RSpec.describe MailChimp::GibbonWrapper do
  let(:mail_chimp_account) { build(:mail_chimp_account) }
  let(:api_prefix) { 'https://us4.api.mailchimp.com/3.0' }

  subject { described_class.new(mail_chimp_account) }

  before do
    lists_response = {
      lists: [
        { id: 'list_id_one', name: 'Test 1', stats: { open_rate: 30 } },
        { id: 'list_id_two', name: 'Test 2', stats: { open_rate: 20 } }
      ]
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(body: lists_response.to_json)
    stub_request(:get, "#{api_prefix}/lists?count=100").to_return(body: lists_response.to_json)
  end

  context '#lists' do
    it 'returns an array of lists associated to the mail_chimp_account' do
      expect(subject.lists.map(&:name)).to eq ['Test 1', 'Test 2']
    end
  end

  context '#lists_available_for_appeals' do
    it 'returns an available lists for appeal. the primary is excluded' do
      # list id from above stub
      mail_chimp_account.primary_list_id = 'list_id_one'
      expect(subject.lists_available_for_appeals.map(&:id)).to eq(['list_id_two'])
    end
  end

  context '#lists_available_for_newsletters' do
    it 'returns all lists if no appeals list.' do
      expect(subject.lists_available_for_newsletters.length).to eq(2)
    end

    it 'excludes the appeals list if specified' do
      create(:mail_chimp_appeal_list, appeal_list_id: 'list_id_one', mail_chimp_account: mail_chimp_account)
      expect(subject.lists_available_for_newsletters.map(&:id)).to eq(['list_id_two'])
    end
  end

  context 'validate_key' do
    let(:mock_gibbon) { double(:mock_gibbon) }
    let(:mock_gibbon_lists) { double(:mock_gibbon_lists) }

    it 'activates the account if the api key is valid' do
      expect(subject).to     receive(:gibbon).and_return(mock_gibbon)
      expect(mock_gibbon).to receive(:lists).and_return(mock_gibbon_lists)
      expect(mock_gibbon_lists).to receive(:retrieve)

      mail_chimp_account.api_key = '555a1932f114322bc50895e5cb5bc385-us4'
      mail_chimp_account.active = false
      mail_chimp_account.save

      subject.validate_key
      expect(mail_chimp_account.active).to eq(true)
    end
  end

  context 'finding a list name' do
    it 'finds a list by list_id' do
      allow_gibbon_wrapper_to_receive_lists
      expect(subject.list('1').name).to eq('foo')
    end

    it 'finds the primary list' do
      allow_gibbon_wrapper_to_receive_lists
      mail_chimp_account.primary_list_id = '1'
      expect(subject.primary_list.name).to eq('foo')
    end
  end

  context 'fetching member data from MailChimp' do
    before do
      lists_response = {
        members: [
          { 'email_address' => 'EMAIL@gmail.com' },
          { 'email_address' => 'email_two@gmail.com' }
        ]
      }
      stub_request(:get, "#{api_prefix}/lists/list_id_one/members?count=100&offset=0").to_return(body: lists_response.to_json)
    end

    context '#list_members' do
      it 'returns an array of lists associated to the mail_chimp_account' do
        expect(subject.list_members('list_id_one')).to match_array [
          { 'email_address' => 'EMAIL@gmail.com' },
          { 'email_address' => 'email_two@gmail.com' }
        ]
      end
    end

    context '#list_emails' do
      it 'returns an array of lists associated to the mail_chimp_account' do
        expect(subject.list_emails('list_id_one')).to match_array ['email@gmail.com', 'email_two@gmail.com']
      end
    end
  end

  def allow_gibbon_wrapper_to_receive_lists
    allow(subject).to receive(:lists).and_return([OpenStruct.new(id: '1', name: 'foo')])
  end
end
