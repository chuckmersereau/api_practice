require 'spec_helper'

describe PunditContext do
  let(:user) { build :user }
  let(:contact) { build :contact }

  subject { PunditContext.new(user, contact) }

  describe 'initialize' do
    it 'defines an extra_context_object accessor' do
      expect(subject.methods).to include :contact
      expect(PunditContext.new(user, build(:account_list)).methods).to include :account_list
    end

    it 'raises if user is not given' do
      expect { PunditContext.new(contact, contact) }.to raise_error ArgumentError
      expect { PunditContext.new(nil, contact) }.to raise_error ArgumentError
      expect { PunditContext.new }.to raise_error ArgumentError
    end
  end

  describe 'extra_context_object accessor' do
    it 'returns the extra context object' do
      expect(subject.contact).to eq contact
    end
  end

  describe '.user' do
    it 'returns the user' do
      expect(subject.user).to eq user
    end
  end
end
