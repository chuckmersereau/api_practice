require 'rails_helper'

RSpec.describe Api::V2::Contacts::ReferrersController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:factory_type) { :contact }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:parent_param) { { contact_id: contact.id } }

  let!(:resource) do
    create(:contact_with_person, account_list: account_list).tap do |referrer|
      contact.contacts_that_referred_me << referrer
    end
  end

  let!(:second_resource) do
    create(:contact_with_person, account_list: account_list).tap do |referrer|
      contact.contacts_that_referred_me << referrer
    end
  end

  let(:correct_attributes) do
    attributes_for(:contact, account_list: account_list)
  end

  include_examples 'index_examples'
end
