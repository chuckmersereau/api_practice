require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::User::GoogleAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:resource_type) { :google_account }
  let!(:resource) { create(:google_account, person: user) }
  let(:id) { resource.id }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { email: 'test@email.com' } }
  let(:incorrect_attributes) { nil }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end