require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::User::OrganizationAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:resource_type) { :organization_account }
  let!(:resource) { create(:organization_account, person: user) }
  let(:id) { resource.id }
  let(:correct_attributes) do
    { organization_id: create(:organization).id, person_id: 200,
      username: 'random_username', password: 'random_password' }
  end
  let(:incorrect_attributes) { { username: nil } }

  before do
    allow_any_instance_of(DataServer).to receive(:validate_username_and_password).and_return(true)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:set_up_account_list)
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
