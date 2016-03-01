require 'spec_helper'

describe AccountList::FromDesignationsFinder, '#account_list' do
  it 'returns nil if no account list contains the specified designations' do
    finder = AccountList::FromDesignationsFinder.new('1', double(id: 0))
    expect(finder.account_list).to be_nil
  end

  it 'returns the account list that contains the specified designations' do
    org = create(:organization)
    da1 = create(:designation_account, designation_number: '1', organization: org)
    da2 = create(:designation_account, designation_number: '2', organization: org)
    da3 = create(:designation_account, designation_number: '3', organization: org)
    account_list = create(:account_list)
    account_list.designation_accounts << [da1, da2, da3]
    finder = AccountList::FromDesignationsFinder.new(%w(1 2), org)

    expect(finder.account_list).to eq account_list
  end

  it 'returns nil if no account list contains all the specified designations' do
    org = create(:organization)
    da1 = create(:designation_account, designation_number: '1', organization: org)
    account_list = create(:account_list)
    account_list.designation_accounts << da1
    create(:designation_account, designation_number: '2', organization: org)
    finder = AccountList::FromDesignationsFinder.new(%w(1 2), org)

    expect(finder.account_list).to be_nil
  end
end
