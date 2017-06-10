require 'rails_helper'

describe ContactSuggestedChangesUpdaterWorker do
  let!(:since_donation_date) { 1.year.ago }
  let!(:account_list) { create(:account_list) }
  let!(:contact_one) { create(:contact, account_list: account_list) }
  let!(:contact_two) { create(:contact, account_list: account_list) }
  let!(:donor_account_one) { create(:donor_account) }
  let!(:donor_account_two) { create(:donor_account) }
  let!(:designation_account_one) { create(:designation_account) }
  let!(:designation_account_two) { create(:designation_account) }
  let!(:donation_one) { create(:donation, donation_date: 1.day.ago, designation_account: designation_account_one, donor_account: donor_account_one) }
  let!(:donation_two) { create(:donation, donation_date: 1.day.ago, designation_account: designation_account_two, donor_account: donor_account_two, created_at: 2.years.ago) }

  let(:user) { account_list.users.first }

  before do
    account_list.designation_accounts << designation_account_one
    account_list.designation_accounts << designation_account_two
    contact_one.donor_accounts << donor_account_one
    contact_two.donor_accounts << donor_account_two
    account_list.users << create(:user)
  end

  it 'updates contacts suggested_changes' do
    expect { ContactSuggestedChangesUpdaterWorker.new.perform(user.id, since_donation_date) }
      .to change { contact_two.reload.suggested_changes }
      .from({})
      .to(pledge_frequency: nil, pledge_amount: nil, status: 'Partner - Special')
    expect(contact_one.reload.suggested_changes).to eq(pledge_frequency: nil, pledge_amount: nil, status: 'Partner - Special')
  end

  context 'only updating contacts with updated donations' do
    before do
      contact_two.update_columns(suggested_changes: { pledge_frequency: nil })
    end

    it 'updates only some contacts suggested_changes' do
      expect { ContactSuggestedChangesUpdaterWorker.new.perform(user.id, since_donation_date) }
        .to_not change { contact_two.reload.suggested_changes }
        .from(pledge_frequency: nil)

      expect(contact_one.reload.suggested_changes).to eq(pledge_frequency: nil, pledge_amount: nil, status: 'Partner - Special')
    end
  end
end
