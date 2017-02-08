require 'rails_helper'

RSpec.describe Api::V2::User::GoogleAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:factory_type) { :google_account }
  let!(:resource) { create(:google_account, person: user) }
  let!(:second_resource) { create(:google_account, person: user) }
  let(:id) { resource.uuid }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { email: 'test@email.com' } }
  let(:incorrect_attributes) { nil }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
