require 'spec_helper'

describe Api::V2Controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { create(:account_list) }

  describe 'controller callbacks' do
    controller(Api::V2Controller) do
      skip_before_action :verify_resource_type
      skip_after_action :verify_authorized

      def index
        render json: params[:filter]
      end

      def create
        render json: params[:data][:attributes]
      end

      def update
        render json: params[:data][:attributes]
      end
    end

    context '#jwt_authorize' do
      it 'doesnt allow not signed in users to access the api' do
        get :index
        expect(response.status).to eq(401)
      end

      it 'allows signed_in users with a valid token to access the api' do
        api_login(user)
        get :index
        expect(response.status).to eq(200)
      end
    end

    context '#filters' do
      let(:contact) { create(:contact) }

      it 'allows a user to filter by id using a uuid' do
        api_login(user)
        get :index, filter: { contact_id: contact.uuid }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['contact_id']).to eq(contact.uuid)
      end

      it 'returns a 404 when a user tries to filter with the id of a resource' do
        api_login(user)
        get :index, filter: { contact_id: contact.id }
        expect(response.status).to eq(404)
        expect(response.body).to include("Resource 'contact' with id '#{contact.id}' does not exist.")
      end

      it 'returns a 404 when a user tries to filter with a resource that does not exist' do
        api_login(user)
        get :index, filter: { contact_id: 'AXXSAASA222Random' }
        expect(response.status).to eq(404)
        expect(response.body).to include("Resource 'contact' with id 'AXXSAASA222Random' does not exist.")
      end
    end

    context '#uuid_to_id conversion in attributes' do
      let(:contact) { create(:contact, account_list: account_list) }
      let(:activity_contact) { create(:activity_contact) }

      it 'turns uuid ending attribute for create actions' do
        api_login(user)
        post :create, data: {
          attributes: {
            account_list_id: account_list.uuid,
            activity_contacts_attributes: [
              id: activity_contact.uuid,
              contact_id: contact.uuid
            ]
          }
        }

        expect(JSON.parse(response.body)['account_list_id']).to eq(account_list.id)
        expect(JSON.parse(response.body)['activity_contacts_attributes'].first['id']).to eq(activity_contact.id)
        expect(JSON.parse(response.body)['activity_contacts_attributes'].first['contact_id']).to eq(contact.id)
      end

      it 'returns a 404 when the uuid is not present in the db table' do
        api_login(user)
        post :create, data: { attributes: { account_list_id: 'AXXSAASA222Random' } }
        expect(response.status).to eq(404)
      end

      it 'returns a 404 when the id is given instead of the uuid' do
        api_login(user)
        post :create, data: { attributes: { account_list_id: account_list.id } }
        expect(response.status).to eq(404)
      end

      it 'turns uuid ending attribute for update actions' do
        api_login(user)
        put :update, id: 'RANDOMUUID', data: { attributes: { account_list_id: account_list.uuid } }
        expect(JSON.parse(response.body)['account_list_id']).to eq(account_list.id)
      end

      it 'returns a 404 when the uuid is not present in the db table' do
        api_login(user)
        put :update, id: 'RANDOMUUID', data: { attributes: { account_list_id: 'AXXSAASA222Random' } }
        expect(response.status).to eq(404)
        expect(response.body).to include("Resource 'account_list' with id 'AXXSAASA222Random' does not exist.")
      end
    end
  end
end
