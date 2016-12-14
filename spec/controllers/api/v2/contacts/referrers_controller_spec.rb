require 'spec_helper'

RSpec.describe Api::V2::Contacts::ReferrersController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :contact }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:parent_param) { { contact_id: contact.uuid } }

  let!(:resource) do
    create(:contact, account_list: account_list).tap do |referrer|
      contact.referrals_to_me << referrer
    end
  end

  let!(:second_resource) do
    create(:contact, account_list: account_list).tap do |referrer|
      contact.referrals_to_me << referrer
    end
  end

  let(:correct_attributes) do
    attributes_for(:contact, account_list: account_list)
  end

  include_examples 'index_examples'
end
