require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::UsersController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:factory_type) { :user }
  let(:resource) { user }
  let(:correct_attributes) { { first_name: 'test_first_name' } }
  let(:incorrect_attributes) { { first_name: nil } }
  let(:unpermitted_attributes) { nil }

  before do
    create(:google_account, person: user) # Test inclusion of related resources.
  end

  include_examples 'show_examples'

  include_examples 'update_examples'
end
