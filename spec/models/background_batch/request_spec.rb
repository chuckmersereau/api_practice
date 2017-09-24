require 'rails_helper'

RSpec.describe BackgroundBatch::Request do
  subject { create :background_batch_request }
  let(:account_list) { create(:account_list) }

  describe '#response_body' do
    it 'should return JSON parsed response_body' do
      subject.response_body = '{ "id": 1234 }'
      expect(subject.response_body).to eq('id' => 1234)
    end

    it 'should return empty hash' do
      expect(subject.response_body).to eq({})
    end
  end

  describe '#formatted_path' do
    it 'should return path with url prepended' do
      expect(subject.formatted_path).to eq('https://api.mpdx.org/api/v2/user')
    end

    it 'should replace %{default_account_list_id} with default account list uuid' do
      subject.path = 'api/v2/account_lists/%{default_account_list_id}/donations'
      account_list = create(:account_list)
      subject.background_batch.user.update(default_account_list: account_list.id)
      expect(subject.formatted_path).to eq("https://api.mpdx.org/api/v2/account_lists/#{account_list.uuid}/donations")
    end
  end

  describe '#formatted_request_headers' do
    it 'should return default set of headers' do
      expect(subject.formatted_request_headers).to eq(
        'accept' => 'application/vnd.api+json',
        'authorization' => "Bearer #{User::Authenticate.new(user: subject.background_batch_user).json_web_token}",
        'content-type' => 'application/vnd.api+json',
        'params' => {}
      )
    end

    it 'should set params as request_params' do
      subject.request_params = { 'test' => 1234 }
      expect(subject.formatted_request_headers['params']).to eq('test' => 1234)
    end

    it 'should merge request_headers and override defaults' do
      subject.request_headers = { 'accept' => 'application/json', 'test' => 1234 }
      expect(subject.formatted_request_headers).to eq(
        'accept' => 'application/json',
        'authorization' => "Bearer #{User::Authenticate.new(user: subject.background_batch_user).json_web_token}",
        'content-type' => 'application/vnd.api+json',
        'params' => {},
        'test' => 1234
      )
    end
  end

  describe '#formatted_request_params' do
    it 'should add default_account_list as filter' do
      subject.default_account_list = true
      subject.background_batch.user.update(default_account_list: account_list.id)
      expect(subject.formatted_request_params).to eq('filter' => { 'account_list_id' => account_list.uuid })
    end

    it 'should merge request_params and override defaults' do
      subject.default_account_list = true
      subject.background_batch.user.update(default_account_list: account_list.id)
      subject.request_params = { 'filter' => { 'account_list_id' => 1234 }, 'test' => 1234 }
      expect(subject.formatted_request_params).to eq(
        'filter' => { 'account_list_id' => 1234 },
        'test' => 1234
      )
    end
  end
end
