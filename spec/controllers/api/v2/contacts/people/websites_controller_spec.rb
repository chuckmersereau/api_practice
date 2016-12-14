require 'spec_helper'

describe Api::V2::Contacts::People::WebsitesController, type: :controller do
  let(:factory_type) { :website }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:websites) { create_list(:website, 2, person: person) }
  let(:website) { websites.first }
  let(:id) { website.uuid }

  let(:resource) { website }
  let(:parent_param) { { contact_id: contact.uuid, person_id: person.uuid } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:website, person: person2, website: 'http://www.example192.com') }
  let(:incorrect_attributes) { attributes_for(:website, person: nil, url: nil) }

  before do
    contact.people << person
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
