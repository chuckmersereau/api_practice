require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::PhonesController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:resource_type) { :phone_number }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:person) { create(:person, contacts: [contact]) }
  let!(:resource) { create(:phone_number, person: person) }
  let!(:second_resource) { create(:phone_number, person: person) }
  let(:id) { resource.uuid }
  let(:parent_param) { { contact_id: contact.uuid, person_id: person.uuid } }
  let(:correct_attributes) { { location: 'home', number: '+11134567890', person_id: person.uuid, country_code: '1', primary: true } }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { { number: nil } }
  let(:factory_type) { :phone_number }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index authorization' do
    it 'does not show resources for person that contact does not own' do
      api_login(user)
      get :index, parent_param.merge(person_id: create(:person).uuid)
      expect(response.status).to eq(404)
    end
  end
end
