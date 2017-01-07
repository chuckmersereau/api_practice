require 'spec_helper'

RSpec.describe Constants::OrganizationList, type: :model do
  subject { Constants::OrganizationList.new }

  before { 5.times { create(:organization) } }

  context '#organizations' do
    it { expect(subject.organizations).to be_a Hash }

    it 'should consist of string/symbol pairs' do
      subject.organizations.each do |id, record|
        expect(id).to be_a Fixnum
        expect(record).to be_a Organization
      end
    end
  end

  context '#id' do
    it { expect(subject.id).to be_blank }
  end
end
