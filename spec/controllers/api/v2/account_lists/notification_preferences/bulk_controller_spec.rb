require 'rails_helper'

describe Api::V2::AccountLists::NotificationPreferences::BulkController, type: :controller do
  include_context 'common_variables'

  let!(:account_list)              { user.account_lists.order(:created_at).first }
  let!(:account_list_id)           { account_list.id }
  let!(:id)                        { resource.id }
  let!(:resource)                  { create(:notification_preference, account_list: account_list) }
  let!(:second_resource)           { create(:notification_preference, account_list: account_list) }
  let!(:third_resource)            { create(:notification_preference, account_list: account_list) }
  let!(:user)                      { create(:user_with_account) }
  let!(:resource_type)             { :notification_preferences }
  let(:first_id)                   { SecureRandom.uuid }
  let(:second_id)                  { SecureRandom.uuid }
  let(:third_id)                   { SecureRandom.uuid }
  let(:full_params)                { bulk_create_attributes.merge(account_list_id: account_list_id) }
  let(:response_body)              { JSON.parse(response.body) }
  let(:response_errors)            { response_body['errors'] }
  let(:unauthorized_resource)      { create(:notification_preference) }

  let!(:correct_attributes) do
    attributes_for(:notification_preference, email: true, task: true)
  end

  def relationships
    {
      notification_type: {
        data: {
          type: 'notification_types',
          id: create(:notification_type).id
        }
      }
    }
  end

  let(:bulk_create_attributes) do
    {
      data: [
        {
          data: {
            type: resource_type,
            id: first_id,
            attributes: correct_attributes
          }.merge(relationships: relationships)
        },
        {
          data: {
            type: resource_type,
            id: second_id,
            attributes: correct_attributes,
            relationships: {}
          }
        },
        {
          data: {
            type: resource_type,
            id: third_id,
            attributes: correct_attributes
          }.merge(relationships: relationships)
        }
      ]
    }
  end

  before do
    api_login(user)
  end

  it 'returns a 200 and the list of created resources' do
    post :create, full_params
    expect(response.status).to eq(200), invalid_status_detail
    expect(response_body.length).to eq(3)
  end

  context "one of the data objects doesn't contain an id" do
    before { full_params[:data].append(data: { attributes: {} }) }
    it 'returns a 400' do
      post :create, full_params
      expect(response.status).to eq(400), invalid_status_detail
    end
  end

  it 'creates the resources which belong to users and do not have errors' do
    expect do
      post :create, full_params
    end.to change { resource.class.count }.by(4)
    expect(response_body.detect { |hash| hash.dig('data', 'id') == first_id }['errors']).to be_blank
    expect(response_body.detect { |hash| hash.dig('id') == second_id }['errors']).to be_present
    expect(response_body.detect { |hash| hash.dig('data', 'id') == third_id }['errors']).to be_blank
  end

  it 'returns error objects for resources that were not created, but belonged to user' do
    expect do
      put :create, full_params
    end.to_not change { second_resource.reload.send(reference_key) }
    response_with_errors = response_body.detect { |hash| hash.dig('id') == second_id }
    expect(response_with_errors['errors']).to be_present
    expect(response_with_errors['errors'].detect do |hash|
      hash.dig('source', 'pointer') == '/data/attributes/notification_type'
    end).to be_present
  end

  context 'resources forbidden' do
    let!(:bulk_create_attributes_with_forbidden_resource) do
      {
        data: [
          {
            data: {
              type: resource_type,
              id: first_id,
              attributes: correct_attributes
            }.merge(relationships: relationships)
          },
          {
            data: {
              type: resource_type,
              id: second_id,
              attributes: correct_attributes,
              relationships: {}
            }
          },
          {
            data: {
              type: resource_type,
              id: third_id,
              attributes: correct_attributes
            }.merge(relationships: relationships)
          }
        ]
      }
    end

    let(:full_params) do
      bulk_create_attributes_with_forbidden_resource.merge(account_list_id: account_list_id)
    end

    it 'does not create resources for users that are not signed in' do
      api_logout

      expect do
        post :create, account_list_id: account_list_id
      end.not_to change { resource.class.count }

      expect(response.status).to eq(401), invalid_status_detail
    end

    it "returns a 403 when users tries to associate resource to an account list that doesn't belong to them" do
      expect do
        post :create, full_params.merge(account_list_id: create(:account_list).id)
      end.not_to change { resource.class.count }

      expect(response.status).to eq(403), invalid_status_detail
    end
  end
end
