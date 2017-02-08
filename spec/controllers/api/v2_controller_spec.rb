require 'rails_helper'

describe Api::V2Controller do
  include_examples 'common_variables'

  let(:user) { create(:user_with_account) }
  let(:account_list) { create(:account_list) }

  describe 'controller callbacks' do
    controller(Api::V2Controller) do
      skip_after_action :verify_authorized

      resource_type :contacts

      def index
        render json: params[:filter] || {}
      end

      def create
        render json: params[:test][:attributes] || {}
      end

      def update
        render json: params[:test][:attributes] || {}
      end
    end

    context '#jwt_authorize' do
      it 'doesnt allow not signed in users to access the api' do
        get :index
        expect(response.status).to eq(401), invalid_status_detail
      end

      it 'allows signed_in users with a valid token to access the api' do
        api_login(user)
        get :index
        expect(response.status).to eq(200), invalid_status_detail
      end
    end

    context '#filters' do
      let(:contact) { create(:contact) }

      it 'allows a user to filter by id using a uuid' do
        api_login(user)
        get :index, filter: { contact_id: contact.uuid }
        expect(response.status).to eq(200), invalid_status_detail
        expect(JSON.parse(response.body)['contact_id']).to eq(contact.id)
      end

      it 'returns a 404 when a user tries to filter with the id of a resource' do
        api_login(user)
        get :index, filter: { contact_id: contact.id }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response.body).to include("Resource 'contact' with id '#{contact.id}' does not exist")
      end

      it 'returns a 404 when a user tries to filter with a resource that does not exist' do
        api_login(user)
        get :index, filter: { contact_id: 'AXXSAASA222Random' }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response.body).to include("Resource 'contact' with id 'AXXSAASA222Random' does not exist")
      end
    end
  end
end
