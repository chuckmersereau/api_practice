require 'rails_helper'

RSpec.describe Api::V2::User::OrganizationAccountsController, type: :controller do
  let(:user) { create(:user) }
  let(:factory_type) { :organization_account }
  let!(:resource) { create(:organization_account, person: user) }
  let!(:second_resource) { create(:organization_account, person: user) }
  let(:id) { resource.uuid }
  let(:unpermitted_relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: create(:user).uuid
        }
      },
      organization: {
        data: {
          type: 'organizations',
          id: create(:organization).uuid
        }
      }
    }
  end

  let(:correct_attributes) do
    { username: 'random_username', password: 'random_password' }
  end

  let(:correct_relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: user.uuid
        }
      },
      organization: {
        data: {
          type: 'organizations',
          id: create(:organization).uuid
        }
      }
    }
  end

  let(:incorrect_attributes) { nil }

  before do
    allow_any_instance_of(DataServer).to receive(:validate_credentials).and_return(true)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:set_up_account_list)
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
