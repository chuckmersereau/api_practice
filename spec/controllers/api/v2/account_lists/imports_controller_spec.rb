require 'rails_helper'

describe Api::V2::AccountLists::ImportsController, type: :controller do
  let(:factory_type) { :import }
  let!(:user) { create(:user_with_account) }
  let!(:fb_account) { create(:facebook_account, person: user) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let(:import) { create(:import, account_list: account_list, user: user, source_account_id: fb_account.id) }
  let(:id) { import.id }

  before do
    stub_request(:get, "https://graph.facebook.com/#{fb_account.remote_id}/friends?access_token=#{fb_account.token}")
      .to_return(body: '{"data": [{"name": "David Hylden","id": "120581"}]}')
    stub_request(:get, "https://graph.facebook.com/120581?access_token=#{fb_account.token}")
      .to_return(body: '{"id": "120581", "first_name": "John", "last_name": "Doe", "relationship_status": "Married", "significant_other":{"id":"120582"}}')
    stub_request(:get, "https://graph.facebook.com/120582?access_token=#{fb_account.token}")
      .to_return(body: '{"id": "120582", "first_name": "Jane", "last_name": "Doe"}')
  end

  let(:resource) { import }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:import, account_list_id: account_list.id, user_id: user.id, source_account_id: fb_account) }
  let(:incorrect_attributes) { { source: nil } }
  let(:unpermitted_attributes) { nil }

  include_examples 'show_examples'
end
