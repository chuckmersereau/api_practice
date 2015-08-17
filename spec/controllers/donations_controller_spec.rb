require 'spec_helper'

describe DonationsController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @designation_account = create(:designation_account)
    @account_list.designation_accounts << @designation_account
    @donor_account = create(:donor_account)
    contact.donor_accounts << @donor_account
  end
  let(:contact) { create(:contact, account_list_id: @account_list.id) }

  describe 'index for a contact' do
    it 'should scope donations to the current contact when a contact_id is present' do
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

  describe 'index' do
    render_views
    it 'should show donation' do
      d = create(:donation, donor_account: @donor_account, designation_account: @designation_account)
      get 'index'
      expect(response.body).to include contact.name
      expect(response.body).to include d.amount.to_s
    end

    it 'should show donation with a start date' do
      create(:donation, donor_account: @donor_account, designation_account: @designation_account,
                        tendered_amount: 33)
      xhr :get, :index, start_date: Date.today
      expect(response.body).to include '33'
    end
  end

  describe 'new' do
    it 'should succeed' do
      xhr :get, :new
      expect(response).to be_success
    end
  end

  describe '#create' do
    let!(:donation) do
      build(:donation, donor_account: @donor_account, designation_account: @designation_account)
    end
    it 'creates a donation when passed valid attributes' do
      expect do
        put :create, format: :js, donation: {
          tendered_amount: '1000',
          'donation_date(1i)': '2015',
          'donation_date(2i)': '4',
          'donation_date(3i)': '11',
          donor_account_id: @donor_account.id
        }
      end.to change { Donation.count }.by(1)
      expect(Donation.last.tendered_amount).to eq 1000
    end

    it "doesn't create a donation when passed invalid attributes" do
      expect do
        put :create, format: :js, donation: { tendered_amount: '', donation_date: '' }
      end.to_not change(Donation, :count)
      expect do
        put :create, format: :js, contact_id: contact.id, donation: { tendered_amount: '', donation_date: '' }
      end.to_not change(Donation, :count)
    end
  end

  describe '#update' do
    let(:donation) do
      create(:donation, donor_account: @donor_account, designation_account: @designation_account)
    end
    it 'updates a donation when passed valid attributes' do
      put :update, format: :js, id: donation.id, donation: { tendered_amount: '1000' }
      expect(donation.reload.tendered_amount).to eq 1000
    end
    it 'redirects when passed invalid attributes' do
      put :update, format: :js, id: donation.id, donation: {
        'donation_date(1i)': '',
        'donation_date(2i)': '',
        'donation_date(3i)': ''
      }
      expect(response).to render_template :edit
    end
  end
end
