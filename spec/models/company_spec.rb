require 'spec_helper'

describe Company do
  it 'should return the company name for to_s' do
    expect(Company.new(name: 'foo').to_s).to eq('foo')
  end

  it 'should delete master_company on destroy if there are no other companies for that master' do
    company = FactoryGirl.create(:company)
    expect do
      company.destroy
    end.to change(MasterCompany, :count).from(1).to(0)
  end

  it 'should NOT delete master_company on destroy if there are other companies for that master' do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:company, master_company: company.master_company)
    expect do
      company.destroy
    end.to_not change(MasterCompany, :count)
  end
end
