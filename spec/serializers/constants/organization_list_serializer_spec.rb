require 'spec_helper'

describe Constants::OrganizationListSerializer do
  subject { Constants::OrganizationListSerializer.new(organization_list) }
  let(:organization_list) { Constants::OrganizationList.new }

  before { 5.times { create(:organization) } }

  context '#organizations' do
    it 'should be an array' do
      expect(subject.organizations).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.organizations.each do |organization|
        expect(organization.size).to eq 2
        expect(organization.first).to be_a(String)
        expect(organization.second).to be_a(Fixnum)
      end
    end
  end

  context '#organizations_exhibit' do
    it { expect(subject.organizations_exhibit).to be_a OrganizationListExhibit }
  end
end
