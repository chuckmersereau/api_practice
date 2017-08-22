require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  describe '#preferences' do
    describe 'no account lists' do
      let(:user) { create(:user) }
      let(:parsed_json) { JSON.parse(UserSerializer.new(user).to_json) }
      it 'setup returns no account_lists' do
        expect(parsed_json['preferences']['setup']).to eq('no account_lists')
      end
    end

    describe 'no default_account_list' do
      let(:account_list) { create(:account_list) }
      let(:user) { create(:user, account_lists: [account_list]) }
      let(:parsed_json) { JSON.parse(UserSerializer.new(user).to_json) }
      it 'setup returns no default_account_list' do
        expect(parsed_json['preferences']['setup']).to eq('no default_account_list')
      end
    end

    describe 'no organization_account on default_account_list' do
      let(:account_list) { create(:account_list) }
      let(:user) do
        create(:user,
               account_lists: [account_list],
               preferences: { default_account_list: account_list.id })
      end
      let(:parsed_json) { JSON.parse(UserSerializer.new(user).to_json) }
      it 'setup returns no organization_account on default_account_list' do
        expect(parsed_json['preferences']['setup']).to eq('no organization_account on default_account_list')
      end
    end

    describe 'organization_account on default_account_list' do
      let!(:organization_account) { create(:organization_account, user: user) }
      let(:account_list) { create(:account_list) }
      let(:user) do
        create(:user,
               account_lists: [account_list],
               preferences: { default_account_list: account_list.id })
      end
      let(:parsed_json) { JSON.parse(UserSerializer.new(user).to_json) }
      it 'setup returns false' do
        expect(parsed_json['preferences']['setup']).to be_nil
      end

      it 'default_account_list returns default_account_list.uuid' do
        expect(parsed_json['preferences']['default_account_list']).to eq(account_list.uuid)
      end
    end
  end
end
