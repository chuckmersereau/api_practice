require 'spec_helper'

RSpec.describe UserSerializer, type: :serializer do
  describe '#default_account_list' do
    let(:account_list)     { create(:account_list) }
    let(:user) { create(:user, preferences: { default_account_list: account_list.id }) }
    let(:parsed_json) { JSON.parse(UserSerializer.new(user).to_json) }

    it 'outputs the preferences default_account_list uuid' do
      expect(parsed_json['preferences']['default_account_list']).to eq(account_list.uuid)
    end
  end
end
