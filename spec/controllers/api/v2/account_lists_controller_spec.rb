require 'spec_helper'
require 'support/shared_controller_examples'

describe Api::V2::AccountListsController, type: :controller do
  let(:factory_type) { :account_list }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:id) { account_list.id }

  let(:resource) { account_list }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:account_list) }
  let(:incorrect_attributes) { { name: nil } }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'
end
