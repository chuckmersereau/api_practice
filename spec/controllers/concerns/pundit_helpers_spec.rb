require 'rails_helper'

class PunditHelpersTestController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  private

  def contact_id_params
    params.require(:data).collect { |hash| hash[:id] }
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end

describe Api::V2Controller do
  let!(:user)         { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:contact_one)  { create(:contact, account_list: account_list) }
  let!(:contact_two)  { create(:contact, account_list: account_list) }

  describe '#bulk_authorize' do
    controller PunditHelpersTestController do
      def show
        @resources = Contact.where(id: contact_id_params)
        render text: bulk_authorize(@resources)
      end
    end

    before do
      routes.draw { get 'show' => 'pundit_helpers_test#show' }
      api_login(user)
    end

    it 'authorizes when current user owns all resources' do
      get :show, data: [{ id: contact_one.id }, { id: contact_two.id }]
      expect(response.status).to eq(200)
      expect(response.body).to eq('true')
    end

    it 'does not authorize when current user owns some of resources' do
      get :show, data: [{ id: contact_one.id }, { id: create(:contact).id }]
      expect(response.status).to eq(403)
      expect(response.body).to_not eq('true')
    end

    it 'does not authorize when current user owns none of resources' do
      get :show, data: [{ id: create(:contact).id }, { id: create(:contact).id }]
      expect(response.status).to eq(403)
      expect(response.body).to_not eq('true')
    end

    it 'does not perform authorization if resources do not exist' do
      expect do
        get :show, data: [{ id: create(:task).id }, { id: create(:task).id }]
      end.to raise_error Pundit::AuthorizationNotPerformedError
    end
  end
end
