require 'rails_helper'

describe Api::V2::ContactsController, type: :controller do
  include_examples 'common_variables'

  let(:factory_type)    { :contact }
  let!(:user)           { create(:user_with_account) }
  let(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let(:contact)         { create(:contact_with_person, status: 'Never Contacted', account_list: account_list) }
  let!(:second_contact) do
    create(:contact, status: 'Ask in Future', account_list: account_list, created_at: 1.week.from_now)
  end
  let!(:third_contact) do
    create(:contact, status: 'Ask in Future', account_list: account_list, created_at: 2.weeks.from_now)
  end
  let(:id) { contact.id }

  let!(:resource) { contact }
  let(:second_resource) { second_contact }

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).id
        }
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

  include_examples 'index_examples'

  describe 'sorting' do
    let!(:sorting_user) { create(:user_with_account) }
    let!(:sorting_account_list) { sorting_user.account_lists.first }
    let!(:contact_1) { create(:contact, name: 'Chan, Emily', account_list: sorting_account_list) }
    let!(:contact_2) { create(:contact, name: 'Chang, Edward', account_list: sorting_account_list) }
    let!(:contact_3) { create(:contact, name: 'Chan, Gene', account_list: sorting_account_list) }
    before { api_login(sorting_user) }
    let(:response_body) { JSON.parse(response.body) }

    it 'sorts name field using C database collation' do
      get :index, sort: 'name'
      expect(response.status).to eq(200), invalid_status_detail
      expect(response_body['data'].map { |c| c['id'] }).to eq [contact_1.id, contact_3.id, contact_2.id]
    end
  end

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  describe 'filtering' do
    before { api_login(user) }

    let(:filter_params) { { status: 'Never Contacted', reverse_status: true } }
    let(:filterer_class) { Contact::Filterer }

    before { Address.create(addressable: Contact.first).update(valid_values: false) }

    include_examples 'filtering examples', action: :index

    context 'account_list_id filter' do
      let!(:user) { create(:user_with_account) }
      let!(:account_list_two) { create(:account_list) }
      let!(:contact_two) { create(:contact, account_list: account_list_two) }
      before { user.account_lists << account_list_two }
      it 'filters results' do
        get :index, filter: { account_list_id: account_list_two.id }

        expect(response.status).to eq(200), invalid_status_detail
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end

    context 'wildcard_search filter' do
      it 'does not blow up with date-like string' do
        expect { get :index, filter: { wildcard_search: '2011-11-01' } }.to_not raise_exception
      end
    end

    context 'with donation details filter' do
      it 'does not blow up' do
        expect { get :index, filter: { donation: 'one', donation_amount_range: { max: 1 } } }.to_not raise_exception
      end
    end
  end

  describe 'Creating a new contact with a default person' do
    it 'will create a default person' do
      api_login(user)
      full_correct_attributes[:data][:attributes][:create_default_person] = true

      expect do
        post :create, full_correct_attributes
      end.to change { Person.count }.by(1)
    end

    it 'will not create a default person' do
      api_login(user)
      full_correct_attributes[:data][:attributes][:create_default_person] = false

      expect do
        post :create, full_correct_attributes
      end.to change { Person.count }.by(0)
    end

    it 'will create a default person if create_default_person is nil' do
      api_login(user)
      full_correct_attributes[:data][:attributes][:create_default_person] = nil

      expect do
        post :create, full_correct_attributes
      end.to change { Person.count }.by(1)
    end
  end

  describe 'Nested Creating / Updating of Resources' do
    describe 'Created a nested Referral with an Account List' do
      lock_time_around

      let(:generated_id) { SecureRandom.uuid }

      let(:params) do
        {
          included: [
            {
              type: 'contacts',
              id: generated_id,
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
                    id: generated_id
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
        expect(resource.contacts_referred_by_me.first.id).to eq generated_id
      end
    end
  end
end
