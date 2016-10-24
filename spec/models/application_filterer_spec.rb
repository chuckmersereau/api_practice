require 'spec_helper'

describe ApplicationFilterer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '.config' do
    it 'returns an empty array' do
      expect(described_class.config(account_list)).to eq []
    end
  end

  describe '.filter_classes' do
    it 'returns an empty array' do
      expect(described_class.filter_classes).to eq []
    end
  end

  describe '#initialize' do
    it 'initializes filters variable' do
      expect(described_class.new(abc: '123').filters).to eq(abc: '123')
    end
    it 'strips filter string params' do
      expect(described_class.new(abc: ' 1 2 3 ').filters).to eq(abc: '1 2 3')
    end
  end

  describe '#filter' do
    it 'returns the resource scope' do
      resource_scope = Contact.all
      expect(described_class.new.filter(resource_scope, account_list)).to eq resource_scope
    end
  end
end
