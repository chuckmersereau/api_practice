require 'spec_helper'

describe DesignationProfile do
  it 'should return name for to_s' do
    expect(DesignationProfile.new(name: 'foo').to_s).to eq('foo')
  end
  it 'should return the first account when asked' do
    dp = FactoryGirl.create(:designation_profile)
    da = FactoryGirl.create(:designation_account)
    dp.designation_accounts << da
    expect(dp.designation_account).to eq(da)
  end
end
