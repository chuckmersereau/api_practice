require 'spec_helper'
require 'pundit_context'

describe PunditContext do
  let(:user)          { build :user }
  let(:contact)       { build :contact }
  let(:person)        { build :person }

  context 'with a user object' do
    subject { PunditContext.new(user) }

    it 'assigns the user' do
      expect(subject.user).to eq user
    end
  end

  context 'without a user object' do
    it 'raises an ArgumentError' do
      expect { PunditContext.new(contact) }.to raise_error ArgumentError
      expect { PunditContext.new(nil) }.to     raise_error ArgumentError
      expect { PunditContext.new }.to          raise_error ArgumentError
    end
  end

  context 'with extra context' do
    subject { PunditContext.new(user, extra_context) }

    let(:extra_context) do
      {
        contact: contact,
        person: person
      }
    end

    it 'creates getters for the extra contexts' do
      expect(subject.contact).to eq contact
      expect(subject.person).to  eq person
    end

    it 'does not create getters for OpenStruct methods' do
      expect(subject.extra_context).to respond_to :to_h
      expect(subject).not_to           respond_to :to_h
    end

    context 'when the extra context is not a hash' do
      let(:extra_context) { "I'm not a hash!" }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
          .with_message 'Extra context (the 2nd param) must be a hash'
      end
    end
  end

  context 'without extra context' do
    subject { PunditContext.new(user) }

    it 'does not create getters' do
      expect(subject).not_to respond_to :contact
      expect(subject).not_to respond_to :person
    end
  end
end
