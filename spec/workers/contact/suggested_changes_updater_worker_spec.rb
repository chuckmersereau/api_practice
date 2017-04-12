require 'rails_helper'

describe Contact::SuggestedChangesUpdaterWorker do
  let!(:since_donation_date) { 1.year.ago }
  let!(:account_list) { create(:account_list) }
  let!(:contact_one) { create(:contact, account_list: account_list) }
  let!(:contact_two) { create(:contact, account_list: account_list) }
  let!(:donor_account_one) { create(:donor_account) }
  let!(:donor_account_two) { create(:donor_account) }
  let!(:designation_account_one) { create(:designation_account) }
  let!(:designation_account_two) { create(:designation_account) }
  let!(:donation_one) { create(:donation, donation_date: 1.day.ago, designation_account: designation_account_one, donor_account: donor_account_one) }
  let!(:donation_two) { create(:donation, donation_date: 1.day.ago, designation_account: designation_account_two, donor_account: donor_account_two) }

  let(:user) { account_list.users.first }

  before do
    account_list.designation_accounts << designation_account_one
    account_list.designation_accounts << designation_account_two
    contact_one.donor_accounts << donor_account_one
    contact_two.donor_accounts << donor_account_two
    account_list.users << create(:user)
  end

  it 'updates contacts suggested_changes' do
    expect { Contact::SuggestedChangesUpdaterWorker.new.perform(user.id, since_donation_date) }
      .to change { contact_two.reload.suggested_changes }
      .from({})
      .to(pledge_frequency: nil, pledge_amount: nil, pledge_currency: nil, status: 'Partner - Special')
    expect(contact_one.reload.suggested_changes).to eq(pledge_frequency: nil, pledge_amount: nil, pledge_currency: nil, status: 'Partner - Special')
  end

  context 'only updating contacts with updated donations' do
    before do
      donation_two.update_columns(created_at: 2.years.ago)
    end

    it 'updates only some contacts suggested_changes' do
      expect { Contact::SuggestedChangesUpdaterWorker.new.perform(user.id, since_donation_date) }
        .to_not change { contact_two.reload.suggested_changes }
        .from({})
      expect(contact_one.reload.suggested_changes).to eq(pledge_frequency: nil, pledge_amount: nil, pledge_currency: nil, status: 'Partner - Special')
    end
  end
end
