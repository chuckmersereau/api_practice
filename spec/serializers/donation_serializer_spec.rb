require 'spec_helper'

describe DonationSerializer do
  let(:account_list) { create(:account_list) }
  let(:donor_account) { create(:donor_account) }
  let!(:contact) do
    create(:contact, account_list: account_list, name: donor_account.name)
    donor_account.link_to_contact_for(account_list)
  end
  let(:user) { create(:user) }
  let(:donation) { create(:donation, donor_account: donor_account) }
  subject do
    serializer = DonationSerializer.new(donation, scope: { account_list: account_list, user: user })
    allow(serializer).to receive(:locale).and_return(:en)
    serializer.as_json[:donation]
  end

  it { should include :amount }
  it { should include :contact_id }
  it { expect(subject[:contact_id]).to be contact.id }
  it { should include :donation_date }
end
