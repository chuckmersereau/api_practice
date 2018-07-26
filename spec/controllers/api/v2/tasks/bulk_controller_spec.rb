require 'rails_helper'

describe Api::V2::Tasks::BulkController, type: :controller do
  let!(:account_list)              { user.account_lists.order(:created_at).first }
  let!(:account_list_id)           { account_list.id }
  let!(:factory_type)              { :task }
  let!(:id)                        { resource.id }
  let!(:incorrect_reference_value) { resource.send(reference_key) }
  let!(:given_reference_key)       { :subject }
  let!(:given_reference_value)     { correct_attributes[:subject] }
  let!(:resource)                  { create(:task, account_list: account_list) }
  let!(:second_resource)           { create(:task, account_list: account_list) }
  let!(:third_resource)            { create(:task, account_list: account_list) }
  let!(:user)                      { create(:user_with_account) }
  let!(:resource_type)             { :tasks }

  let!(:correct_attributes) do
    attributes_for(:task, subject: 'Michael Bluth', tag_list: 'tag1')
  end

  let!(:incorrect_attributes) do
    attributes_for(:task, subject: nil)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list_id
        }
      }
    }
  end

  include_examples 'bulk_create_examples'

  include_examples 'bulk_update_examples'

  include_examples 'bulk_destroy_examples'

  describe '#post' do
    before { api_login(user) }

    let(:bulk_create_form_data) do
      [{ data: { type: resource_type, id: SecureRandom.uuid, attributes: correct_attributes, relationships: relationships } }]
    end

    context 'with specified fields' do
      it 'only returns specific fields' do
        post :create, data: bulk_create_form_data, fields: { tasks: 'subject' }

        expect(JSON.parse(response.body)[0]['data']['attributes'].keys).to eq ['subject']
      end

      it 'will leave subject_hidden as false' do
        post :create, data: bulk_create_form_data, fields: { tasks: 'subject,subject_hidden' }
        attributes = JSON.parse(response.body)[0]['data']['attributes']
        expect(attributes['subject_hidden']).to eq(false)
      end
    end

    context 'with a missing subject' do
      let!(:contact) { create(:contact, account_list: account_list) }
      let(:contact_relationship) do
        {
          account_list: {
            data: {
              type: 'account_lists',
              id: account_list_id
            }
          },
          contacts: {
            data: [
              {
                id: contact.id,
                type: 'contacts'
              }
            ]
          }
        }
      end

      let!(:contact_attributes) { attributes_for(:task, subject: nil, activity_type: 'Call') }
      let(:bulk_create_form_data_with_missing_subject) do
        [{ data: { type: resource_type, id: SecureRandom.uuid, attributes: contact_attributes, relationships: contact_relationship } }]
      end

      it 'will set the subject_hidden to true' do
        post :create, data: bulk_create_form_data_with_missing_subject, fields: { tasks: 'subject,subject_hidden' }
        attributes = JSON.parse(response.body)[0]['data']['attributes']
        expect(attributes['subject_hidden']).to eq(true)
        expect(attributes['subject']).to eq("Call #{contact.name}")
      end
    end
  end
end
