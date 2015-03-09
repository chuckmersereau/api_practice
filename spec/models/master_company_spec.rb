require 'spec_helper'

describe MasterCompany do
  it 'should find an existing master company' do
    company = FactoryGirl.create(:company)
    expect do
      MasterCompany.find_or_create_for_company(FactoryGirl.build(:company)).should == company.master_company
    end.to_not change(MasterCompany, :count)
  end

  it 'should create a new master company' do
    expect do
      MasterCompany.find_or_create_for_company(FactoryGirl.build(:company))
    end.to change(MasterCompany, :count)
  end
end
