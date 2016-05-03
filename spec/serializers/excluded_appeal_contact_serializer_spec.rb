require 'spec_helper'

describe ExcludedAppealContactSerializer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:designation_account) do
    da = create(:designation_account)
    account_list.designation_accounts << da
    da
  end
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:donor_account) { create(:donor_account) }
  let(:contact) do
    create(:contact, account_list: account_list, name: donor_account.name)
    donor_account.link_to_contact_for(account_list)
  end

  subject do
    create(:donation, donation_date: 1.month.ago,
                      donor_account: donor_account, designation_account: designation_account)

    excluded = appeal.excluded_appeal_contacts.create(contact: contact,
                                                      reasons: ['recent_increase'])
    ExcludedAppealContactSerializer.new(excluded).as_json[:excluded_appeal_contact]
  end

  it 'has correct attributes' do
    expect(subject.keys).to include :id
    expect(subject.keys).to include :contact
    expect(subject.keys).to include :appeal_id
    expect(subject.keys).to include :donations
  end

  it 'renders basic donations data' do
    expect(subject[:donations].count).to be 1
  end
end
