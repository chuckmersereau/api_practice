require 'rails_helper'

RSpec.describe Api::V2::Contacts::AddressesController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:resource_type) { :address }
  let(:contact) { create(:contact, account_list: user.account_lists.order(:created_at).first) }
  let!(:resource) { create(:address, addressable: contact, source_donor_account: build(:donor_account)) }
  let!(:second_resource) { create(:address, addressable: contact) }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id } }
  let(:parent_association) { :addressable }
  let(:correct_attributes) { { street: '123 Street' } }
  let(:incorrect_attributes) { nil }
  let!(:not_destroyed_scope) { Address.current }
  let(:factory_type) { :address }

  before(:each) do
    stub_request(:get, %r{api\.smartystreets\.com/.*}).to_return(status: 200, body: '{}', headers: {})
  end

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples', except: [:includes]

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index authorization' do
    it 'does not show resources for contact that user does not own' do
      api_login(user)
      contact = create(:contact, account_list: create(:user_with_account).account_lists.order(:created_at).first)
      get :index, contact_id: contact.id
      expect(response.status).to eq(403)
    end
  end
end
