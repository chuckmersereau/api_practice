require 'spec_helper'

RSpec.describe Api::V2::UsersController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:factory_type) { :user }
  let(:resource) { user }

  let(:correct_attributes) { { first_name: 'test_first_name', preferences: { locale: 'fr-FR' } } }
  let(:incorrect_attributes) { { first_name: nil } }
  let(:unpermitted_attributes) { nil }

  let(:given_update_reference_key) { :locale }
  let(:given_update_reference_value) { 'fr-FR' }

  let(:second_account_list) { create(:account_list, users: [user]) }

  before do
    create(:google_account, person: user) # Test inclusion of related resources.
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  context 'update#default_account_list' do
    it 'correctly saves default_account_list when passed as a preference' do
      api_login(user)
      put :update, data: {
        id: user.uuid,
        type: 'users',
        attributes: {
          preferences: {
            default_account_list: second_account_list.uuid
          },
          updated_in_db_at: user.updated_at }
      }
      expect(
        JSON.parse(response.body)['data']['attributes']['preferences']['default_account_list']
      ).to eq(second_account_list.uuid)
    end
  end
end
