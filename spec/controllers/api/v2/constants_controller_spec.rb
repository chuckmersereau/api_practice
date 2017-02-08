require 'rails_helper'

RSpec.describe Api::V2::ConstantsController, type: :controller do
  include_examples 'common_variables'

  let(:user) { create(:user_with_account) }

  describe '#index' do
    it 'shows resources to users that are signed in' do
      api_login(user)
      get :index
      expect(response.status).to eq(200)
    end

    it 'does not shows resources to users that are not signed in' do
      get :index
      expect(response.status).to eq(401)
    end
  end

  describe '#index fields' do
    let(:resource_type) { 'constant_list' }
    let(:parent_param_if_needed) { Hash.new }
    let(:serializer) { ConstantListSerializer.new(ConstantList.new) }

    include_examples 'sparse fieldsets examples',
                     action: :index,
                     expected_response_code: 200
  end
end
