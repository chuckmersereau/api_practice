require 'spec_helper'

describe DesignationAccount::DupByBalanceFix, '#deactivate_dups!' do
  it 'returns false if no designation accounts were marked inactive' do
    da = create(:designation_account, active: true, balance: nil)

    result = DesignationAccount::DupByBalanceFix.deactivate_dups(DesignationAccount.all)

    expect(result).to be false
    expect(da.reload.active).to be true
  end

  it 'returns true and deactivates single person designation for dup balance' do
    da1 = create(:designation_account, name: 'John', active: true, balance: 10.1)
    da2 = create(:designation_account, name: 'John and Jane', active: true,
                                       balance: 10.1)

    result = DesignationAccount::DupByBalanceFix.deactivate_dups(DesignationAccount.all)

    expect(result).to be true
    expect(da1.reload.active).to be false
    expect(da1.balance).to eq 0.0
    expect(da2.reload.active).to be true
  end

  it 'does not consider a zero balance to be a dup' do
    da1 = create(:designation_account, name: 'John 1', active: true, balance: 0)
    da2 = create(:designation_account, name: 'John 2', active: true,
                                       balance: 0)

    result = DesignationAccount::DupByBalanceFix.deactivate_dups(DesignationAccount.all)

    expect(result).to be false
    expect(da1.reload.active).to be true
    expect(da2.reload.active).to be true
  end
end
