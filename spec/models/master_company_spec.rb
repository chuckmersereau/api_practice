require 'rails_helper'

describe MasterCompany do
  it 'should find an existing master company' do
    company = FactoryBot.create(:company)
    expect do
      expect(MasterCompany.find_or_create_for_company(FactoryBot.build(:company)))
        .to eq(company.master_company)
    end.to_not change(MasterCompany, :count)
  end

  it 'should create a new master company' do
    expect do
      MasterCompany.find_or_create_for_company(FactoryBot.build(:company))
    end.to change(MasterCompany, :count)
  end
end
