require 'rails_helper'

describe Api::V2::AccountLists::Imports::GoogleController, type: :controller do
  let(:factory_type) { :import }
  let(:resource_type) { :imports }

  let!(:user) { create(:user_with_account) }
  let!(:google_account) { create(:google_account, person: user) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:import) { create(:google_import, account_list: account_list, user: user) }
  let(:id) { import.id }

  let(:resource) { import }
  let(:parent_param) { { account_list_id: account_list_id } }

  let(:correct_attributes) do
    {
      'in_preview' => false,
      'tag_list' => 'test,poster',
      'groups' => [
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d',
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/f'
      ],
      'import_by_group' => 'true',
      'override' => 'true',
      'source' => 'google',
      'group_tags' => {
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/6' => 'my-contacts',
        'http://www.google.com/m8/feeds/groups/test%40gmail.com/base/d' => 'friends'
      }
    }
  end

  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      },
      user: {
        data: {
          type: 'users',
          id: user.id
        }
      },
      source_account: {
        data: {
          type: 'google_accounts',
          id: google_account.id
        }
      }
    }
  end

  let(:incorrect_attributes) { { source: nil } }

  let(:unpermitted_attributes) { nil }

  include_examples 'create_examples'

  describe '#create' do
    it 'defaults source to google' do
      api_login(user)
      post :create, full_correct_attributes.merge(source: 'bogus')
      import = Import.find_by_id(JSON.parse(response.body)['data']['id'])
      expect(import.source).to eq 'google'
    end

    it 'defaults user_id to current user' do
      api_login(user)
      full_correct_attributes[:data][:relationships].delete(:user)
      post :create, full_correct_attributes
      import = Import.find_by_id(JSON.parse(response.body)['data']['id'])
      expect(import.user_id).to eq user.id
    end
  end
end
