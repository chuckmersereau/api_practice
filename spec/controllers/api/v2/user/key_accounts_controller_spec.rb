require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::User::KeyAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:factory_type) { :key_account }
  let!(:resource) { create(:key_account, person: user) }
  let!(:second_resource) { create(:key_account, person: user) }
  let(:id) { resource.id }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { email: 'test@email.com', remote_id: 200 } }
  let(:incorrect_attributes) { { remote_id: nil } }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
