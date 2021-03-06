require 'rails_helper'

RSpec.describe Api::V2::Contacts::PeopleController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:resource_type) { :person }
  let(:contact) { create(:contact, account_list: account_list) }
  let!(:resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let!(:second_resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id } }
  let(:correct_attributes) do
    { first_name: 'Billy', email_address: { email: 'billy@internet.com' }, updated_at: 1.day.from_now }
  end
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
    include_examples 'update_examples'
    include_examples 'show_examples'
    include_examples 'destroy_examples'
  end

  context 'a specific contact' do
    let(:parent_param) { { contact_id: contact.id } }
    include_examples 'index_examples'
  end

  context 'filter by phone_number_valid' do
    let(:filter_params) { { phone_number_valid: 'false' } }
    before { Contact.first.people.first.delete }
    include_examples 'filtering examples', action: :index
  end

  context 'account_list_id filter' do
    let!(:account_list_two) { create(:account_list, users: [user]) }
    let!(:person_two) { create(:contact_with_person, account_list: account_list_two).primary_person }

    it 'filters results' do
      api_login(user)
      get :index, filter: { account_list_id: account_list_two.id }

      expect(response.status).to eq(200), invalid_status_detail
      expect(JSON.parse(response.body)['data'].length).to eq(1)
    end
  end

  describe 'Nested Examples' do
    describe 'Creating / Updating a Facebook Account nested under Person' do
      let(:generated_id) { SecureRandom.uuid }

      let(:params) do
        {
          id: resource.id,
          contact_id: contact.id,
          data: {
            type: 'people',
            id: resource.id,
            attributes: {
              updated_in_db_at: resource.updated_at
            },
            relationships: {
              facebook_accounts: {
                data: [
                  {
                    type: 'facebook_accounts',
                    id: generated_id
                  }
                ]
              }
            }
          },
          included: [
            {
              type: 'facebook_accounts',
              id: generated_id,
              attributes: {
                username: 'captain.america'
              }
            }
          ]
        }
      end

      it 'Correctly creates the Facebook Account' do
        expect(resource.facebook_accounts.count).to eq(0)

        api_login(user)
        put :update, params

        expect(response.status).to eq(200), invalid_status_detail

        expect(resource.reload.facebook_accounts.count).to eq(1)
        expect(resource.facebook_accounts.first.id).to eq generated_id
        expect(resource.facebook_accounts.first.username).to eq 'captain.america'
      end
    end

    describe 'Creating / Updating a Linkedin Account nested under Person' do
      let(:linkedin_account) do
        create(:linkedin_account, public_url: 'https://linkedin.com/old-url',
                                  person: resource)
      end

      let(:params) do
        {
          id: resource.id,
          contact_id: contact.id,
          data: {
            type: 'people',
            id: resource.id,
            attributes: {
              updated_in_db_at: resource.updated_at
            },
            relationships: {
              linkedin_accounts: {
                data: [
                  {
                    type: 'linkedin_accounts',
                    id: linkedin_account.id
                  }
                ]
              }
            }
          },
          included: [
            {
              type: 'linkedin_accounts',
              id: linkedin_account.id,
              attributes: {
                public_url: 'https://linkedin.com/new-url'
              }
            }
          ]
        }
      end

      it 'Correctly creates the Linkedin Account' do
        expect(linkedin_account.public_url).to eq 'https://linkedin.com/old-url'

        api_login(user)
        put :update, params

        expect(response.status).to eq(200), invalid_status_detail
        expect(linkedin_account.reload.public_url).to eq 'https://linkedin.com/new-url'
      end
    end

    describe 'Creating / Updating a Phone Number nested under Person' do
      let(:generated_id) { SecureRandom.uuid }

      let(:params) do
        {
          id: resource.id,
          contact_id: contact.id,
          data: {
            type: 'people',
            id: resource.id,
            attributes: {
              updated_in_db_at: resource.updated_at
            },
            relationships: {
              phone_numbers: {
                data: [
                  {
                    type: 'phone_numbers',
                    id: generated_id
                  }
                ]
              }
            }
          },
          included: [
            {
              type: 'phone_numbers',
              id: generated_id,
              attributes: {
                number: '5011231234'
              }
            }
          ]
        }
      end

      it 'Correctly creates the Phone Number' do
        expect(resource.facebook_accounts.count).to eq(0)

        api_login(user)
        put :update, params

        expect(response.status).to eq(200), invalid_status_detail

        expect(resource.reload.phone_numbers.count).to eq(1)
        expect(resource.phone_numbers.first.id).to eq generated_id
        expect(resource.phone_numbers.first.number).to eq '+5011231234'
      end
    end

    describe 'Creating / Updating an Email Address under Person' do
      let(:generated_id) { SecureRandom.uuid }

      let(:params) do
        {
          id: resource.id,
          contact_id: contact.id,
          data: {
            type: 'people',
            id: resource.id,
            attributes: {
              updated_in_db_at: resource.updated_at
            },
            relationships: {
              email_addresses: {
                data: [
                  {
                    type: 'email_addresses',
                    id: generated_id
                  }
                ]
              }
            }
          },
          included: [
            {
              type: 'email_addresses',
              id: generated_id,
              attributes: {
                email: 'tester@testing.com'
              }
            }
          ]
        }
      end

      it 'Correctly creates the Email Address' do
        expect(resource.email_addresses.count).to eq(1)

        api_login(user)
        put :update, params

        expect(response.status).to eq(200), invalid_status_detail

        expect(resource.reload.email_addresses.count).to eq(2)
        expect(resource.email_addresses.last.id).to eq generated_id
        expect(resource.email_addresses.last.email).to eq 'tester@testing.com'
      end
    end
  end
end
