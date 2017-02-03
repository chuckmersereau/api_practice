require 'spec_helper'

RSpec.describe Api::V2::User::OptionsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :user_option }
  let!(:resource) { create(:user_option, user: user, created_at: 10.minutes.ago) }
  let!(:second_resource) { create(:user_option, user: user) }
  let(:id) { resource.key }
  let(:correct_attributes) { attributes_for(:user_option) }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { nil }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
