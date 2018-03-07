require 'rails_helper'

describe DataServerUk do
  let(:account_list) { create(:account_list) }
  let!(:organization) { create(:organization, name: 'MyString') }
  let!(:person) { create(:person) }
  let!(:organization_account) { build(:organization_account, person: person, organization: organization) }
  let!(:data_server) { described_class.new(organization_account) }
  let(:profile) do
    create(:designation_profile, organization: organization, user: person.to_user, account_list: account_list)
  end

  it 'should update a designation account balance when there is more than one designation number' do
    stub_request(:post, /.*accounts/).to_return(
      body: '"EMPLID","EFFDT","BALANCE","ACCT_NAME"'\
            "\n"\
            '"0000000,0000001","2012-03-23 16:01:39.0","123.45","Test Account"'\
            "\n"
    )
    designation_account = create(:designation_account, organization: organization, designation_number: '0000000', balance: 0)
    designation_account2 = create(:designation_account, organization: organization, designation_number: '0000001', balance: 0)
    data_server.import_profile_balance(profile)
    expect(designation_account.reload.balance).to eq(123.45)
    expect(designation_account2.reload.balance).to eq(123.45)
  end
end
