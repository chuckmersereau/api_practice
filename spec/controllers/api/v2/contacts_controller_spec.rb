require 'rails_helper'

describe Api::V2::ContactsController, type: :controller do
  let(:factory_type)    { :contact }
  let!(:user)           { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:contact)         { create(:contact_with_person, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let(:id)              { contact.uuid }

  let!(:resource) { contact }
  let(:second_resource) { second_contact }

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).uuid }
      }
    }
  end

  let(:correct_attributes) do
    {
      name: 'Test Name'
    }
  end

  let(:incorrect_attributes) do
    {
      name: nil
    }
  end

  let(:reference_key) { :name }
  let(:reference_value) { correct_attributes[:name] }
  let(:incorrect_reference_value) { resource.send(reference_key) }
  let(:incorrect_attributes) { attributes_for(:contact, name: nil) }
  let(:sorting_param) { :name }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  describe 'filtering' do
    before { api_login(user) }

    let(:filter_params) { { address_valid: 'false' } }
    let(:filterer_class) { Contact::Filterer }
    before { Address.create(addressable: Contact.first).update(valid_values: false) }
    include_examples 'filtering examples', action: :index

    context 'account_list_id filter' do
      let!(:user) { create(:user_with_account) }
      let!(:account_list_two) { create(:account_list) }
      let!(:contact_two) { create(:contact, account_list: account_list_two) }
      before { user.account_lists << account_list_two }
      it 'filters results' do
        get :index, filter: { account_list_id: account_list_two.uuid }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end

  describe 'Nested Creating / Updating of Resources' do
    describe 'Created a nested Referral with an Account List' do
      let(:generated_uuid) { SecureRandom.uuid }

      let(:params) do
        {
          included: [
            {
              type: 'contacts',
              id: generated_uuid,
              attributes: {
                name: 'thompson, jim and jan',
                primary_person_first_name: 'jim',
                primary_person_last_name: 'thomson',
                primary_person_email: 'jim.thompson@example.com',
                primary_person_phone: '4074969081',
                spouse_first_name: 'jan',
                spouse_last_name: 'thompson'
              },
              relationships: {
                account_list: {
                  data: {
                    type: 'account_lists',
                    id: account_list_id
                  }
                }
              }
            }
          ],
          data: {
            type: 'contacts',
            id: id,
            attributes: {
              updated_in_db_at: Time.current
            },
            relationships: {
              contacts_referred_by_me: {
                data: [
                  {
                    type: 'contacts',
                    id: generated_uuid
                  }
                ]
              }
            }
          },
          id: id
        }
      end

      it 'creates the nested referral' do
        expect(resource.contact_referrals_by_me.count).to eq(0)

        api_login(user)
        put :update, params

        expect(resource.reload.contact_referrals_by_me.count).to          eq(1)
        expect(resource.contacts_referred_by_me.first.name).to            eq 'thompson, jim and jan'
        expect(resource.contacts_referred_by_me.first.account_list_id).to eq account_list.id
        expect(resource.contacts_referred_by_me.first.uuid).to            eq generated_uuid
      end
    end
  end
end
