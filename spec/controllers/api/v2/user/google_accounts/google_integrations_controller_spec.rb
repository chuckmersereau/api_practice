require 'rails_helper'

RSpec.describe Api::V2::User::GoogleAccounts::GoogleIntegrationsController, type: :controller do
  before do
    stub_request(:get, 'https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest')
      .to_return(status: 200, body: '', headers: {})
  end

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:google_account) { create(:google_account, person: user) }

  let(:factory_type) do
    :google_integration
  end

  let!(:resource) do
    create(:google_integration, account_list: account_list, google_account: google_account)
  end

  let!(:second_resource) do
    create(:google_integration, account_list: account_list, google_account: google_account, created_at: 1.hour.ago)
  end

  let(:id) { resource.uuid }
  let(:parent_param) { { google_account_id: google_account.uuid } }

  before do
    allow_any_instance_of(Person::GoogleAccount).to receive(:contact_groups).and_return(
      [
        Person::GoogleAccount::ContactGroup.new(
          id: 'contact_group_id_0',
          title: 'System Group: My Family',
          uuid: 'contact_group_id_0',
          created_at: Date.today,
          updated_at: Date.today
        )
      ]
    )
  end

  # This is required!
  let(:correct_attributes) do
    {
      calendar_id: 'test@test.com',
      calendar_name: 'test123',
      calendar_integration: true,
      calendar_integrations: [],
      contacts_integration: true,
      email_integration: true
    }
  end

  let(:unpermitted_attributes) do
    # A hash of attributes that include unpermitted attributes for the current user to update
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: create(:account_list).id } }
    # --
    # If there aren't attributes that are unpermitted,
    # you need to specifically return `nil`
  end

  let(:incorrect_attributes) do
    nil
  end

  include_examples 'index_examples'
  include_examples 'show_examples'
  include_examples 'create_examples'
  include_examples 'update_examples'
  include_examples 'destroy_examples'
end
