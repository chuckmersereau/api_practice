require 'spec_helper'

describe ReportsController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @designation_account = create(:designation_account)
    @account_list.designation_accounts << @designation_account
  end
  let(:donor_account) { create(:donor_account) }
  let!(:contact) do
    create(:contact, account_list_id: @account_list.id, pledge_amount: 100,
                     status: 'Partner - Financial')
  end

  describe '#contributions' do
    before do
      contact.donor_accounts << donor_account
      create(:donation, donor_account: donor_account, designation_account: @designation_account,
                        donation_date: 1.month.ago)
    end
    it 'successfully loads html' do
      get 'contributions'
      expect(response).to be_success
    end

    it 'loads last years report' do
      contact.pledge_frequency = nil
      create(:donation, donor_account: donor_account, designation_account: @designation_account,
                        donation_date: 13.months.ago)
      get 'contributions', start_date: Date.today.end_of_month - 1.year
      expect(response).to be_success
    end

    it 'successfully loads csv' do
      get 'contributions', format: 'csv'
      expect(response).to be_success
    end
  end

  describe '#monthly_pledges_not_given' do
    before do
      subject.setup_dates
      contact.donor_accounts << donor_account
    end

    it "includes partners who haven't given yet" do
      expect(subject.monthly_pledges_not_given).to eq 100
    end

    it "doesn't include giving partner" do
      create(:donation, donor_account: donor_account, designation_account: @designation_account)
      expect(subject.monthly_pledges_not_given).to eq 0
    end

    it "includes partners who haven't given in a while" do
      create(:donation, donor_account: donor_account, designation_account: @designation_account,
                        donation_date: 2.years.ago)
      expect(subject.monthly_pledges_not_given).to eq 100
    end

    it "doesn't include partners who have multiple donor accounts" do
      da2 = create(:donor_account)
      contact.donor_accounts << da2
      create(:donation, donor_account: da2, designation_account: @designation_account)
      expect(subject.monthly_pledges_not_given).to eq 0
    end
  end
end
