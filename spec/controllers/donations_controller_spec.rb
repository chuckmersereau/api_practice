require 'spec_helper'

describe DonationsController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @designation_account = create(:designation_account)
    @account_list.designation_accounts << @designation_account
    @donor_account = create(:donor_account)
  end

  describe 'index' do
    let(:contact) { create(:contact, account_list_id: @account_list.id) }

    it 'should scope donations to the current contact when a contact_id is present' do
      contact.donor_accounts << @donor_account
      create(:donation, donor_account: @donor_account, designation_account: @designation_account)
      get :index, contact_id: contact.id
      expect(assigns(:contact)).to eq(contact)
      expect(assigns(:donations).total_entries).to eq(1)
    end

    it 'should not find any donations for a contact without a donor account' do
      get :index, contact_id: contact.id
      expect(assigns(:donations).total_entries).to eq(0)
    end

    it 'should set up chart variables if page parameter is not present' do
      get :index, contact_id: contact.id
      expect(assigns(:by_month)).not_to be_nil
    end
  end
end
