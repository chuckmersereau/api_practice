require 'rails_helper'

RSpec.describe Api::V2::Contacts::PeopleController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:resource_type) { :person }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let!(:resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let!(:second_resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let(:id) { resource.uuid }
  let(:parent_param) { { contact_id: contact.uuid } }
  let(:correct_attributes) { { first_name: 'Billy', email_address: { email: 'billy@internet.com' }, updated_at: Time.now + 1.day } }
  let(:incorrect_attributes) { nil }
  let(:factory_type) { :person }

  let(:resource_scope) { contact.people }

  before do
    create(:email_address, person: resource) # Test inclusion of related resources.
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  context 'all contacts' do
    let(:parent_param) { {} }
    include_examples 'index_examples'
  end

  context 'a specific contact' do
    let(:parent_param) { { contact_id: contact.uuid } }
    include_examples 'index_examples'
  end

  context 'filter by phone_number_valid' do
    let(:filter_params) { { phone_number_valid: 'false' } }
    before { Contact.first.people.first.delete }
    include_examples 'filtering examples', action: :index
  end

  describe 'Creating / Updating a Facebook Account nested under person' do
    let(:generated_uuid) { SecureRandom.uuid }

    let(:params) do
      {
        id: resource.uuid,
        contact_id: contact.uuid,
        data: {
          type: 'people',
          id: resource.uuid,
          attributes: {
            updated_in_db_at: Time.current
          },
          relationships: {
            facebook_accounts: {
              data: [
                {
                  type: 'facebook_accounts',
                  id: generated_uuid
                }
              ]
            }
          }
        },
        included: [
          {
            type: 'facebook_accounts',
            id: generated_uuid,
            attributes: {
              username: 'captain.america',
              updated_in_db_at: Time.current
            }
          }
        ]
      }
    end

    it 'Correctly creates the Linkedin Account' do
      expect(resource.facebook_accounts.count).to eq(0)

      api_login(user)
      put :update, params

      expect(response.status).to eq(200), invalid_status_detail

      expect(resource.reload.facebook_accounts.count).to   eq(1)
      expect(resource.facebook_accounts.first.uuid).to     eq generated_uuid
      expect(resource.facebook_accounts.first.username).to eq 'captain.america'
    end
  end
end
