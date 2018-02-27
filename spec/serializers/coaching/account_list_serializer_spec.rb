require 'rails_helper'

RSpec.describe Coaching::AccountListSerializer, type: :serializer do
  let(:organization) { create(:organization) }
  let(:account_list) { create(:account_list, salary_organization_id: organization) }

  let(:serializer) { Coaching::AccountListSerializer.new(account_list) }
  subject { serializer }

  context '#balance' do
    it { expect(subject.balance).to be_a String }
    it { expect(subject.balance).to include '$' }
  end

  context '#committed' do
    it { expect(subject.committed).to be_a Numeric }
  end

  context '#received' do
    it { expect(subject.received).to be_a Numeric }
  end

  context '#progress' do
    it { expect(subject.progress).to be_a Hash }
    it do
      expect(subject.progress.keys).to include :monthly_goal, :pledged_percent,
                                               :received_pledges, :total_pledges
    end
  end
end
