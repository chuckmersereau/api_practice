require 'rails_helper'

RSpec.describe Api::V2::Contacts::DonationAmountRecommendationsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:resource_type) { :donation_amount_recommendation }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let!(:organization) { create :organization }
  let!(:designation_account) { create :designation_account, organization: organization }
  let!(:donor_account1) { create :donor_account, organization: organization, account_number: '123' }
  let!(:donor_account2) { create :donor_account, organization: organization, account_number: '456' }
  let!(:resource) do
    create(
      :donation_amount_recommendation,
      designation_account: designation_account,
      donor_account: donor_account1
    )
  end
  let!(:second_resource) do
    create(
      :donation_amount_recommendation,
      designation_account: designation_account,
      donor_account: donor_account2
    )
  end
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id } }
  let(:parent_association) { :donation_amount_recommendations }
  let(:factory_type) { :donation_amount_recommendation }
  let(:correct_attributes) do
    {
      suggested_pledge_amount: 123,
      suggested_special_amount: 456,
      ask_at: Time.zone.now + 1.day,
      started_at: Time.zone.now - 2.years
    }
  end

  before(:each) do
    designation_account.account_lists << account_list
    contact.donor_accounts << donor_account1
    contact.donor_accounts << donor_account2
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  describe '#index authorization' do
    it 'does not show resources for contact that user does not own' do
      api_login(user)
      contact = create(:contact, account_list: create(:user_with_account).account_lists.first)
      get :index, contact_id: contact.id
      expect(response.status).to eq(403)
    end
  end
end
