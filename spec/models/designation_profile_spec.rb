require 'rails_helper'

describe DesignationProfile do
  let!(:designation_profile) { create(:designation_profile) }
  let!(:designation_account) { create(:designation_account) }

  it 'should return name for to_s' do
    expect(DesignationProfile.new(name: 'foo').to_s).to eq('foo')
  end

  it 'should return the first account when asked' do
    designation_profile.designation_accounts << designation_account
    expect(designation_profile.designation_account).to eq(designation_account)
  end

  it 'should create associated balance record when balance is updated' do
    expect { create(:designation_profile, balance: 10.0) }.to change { Balance.count }.by(1)
    expect { designation_profile.update(balance: 20.0) }.to change { Balance.count }.by(1)
    expect { designation_profile.update(balance: 20.0) }.to change { Balance.count }.by(0)
  end

  it 'should not create associated balance record when balance is updated to nil' do
    expect { designation_profile.update(balance: nil) }.to change { Balance.count }.by(0)
  end
end
