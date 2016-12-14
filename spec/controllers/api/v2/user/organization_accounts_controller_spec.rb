require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::User::OrganizationAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:factory_type) { :organization_account }
  let!(:resource) { create(:organization_account, person: user) }
  let!(:second_resource) { create(:organization_account, person: user) }
  let(:id) { resource.uuid }
  let(:unpermitted_attributes) do
    { username: 'random_username', password: 'random_password',
      organization_id: create(:organization).uuid, person_id: create(:user).uuid }
  end

  let(:correct_attributes) do
    { username: 'random_username', password: 'random_password',
      organization_id: create(:organization).uuid, person_id: user.uuid }
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
