require 'rails_helper'

RSpec.describe RunOnce::EmailAddressUniqueAndCaseSensitiveWorker do
  let(:person) { create(:person) }
  let(:email_address_1) { create(:email_address, person: person) }
  let(:email_address_2) { create(:email_address, person: person) }

  before do
    email_address_1.update_column(:email, 'test123@example.com')
    email_address_2.update_column(:email, 'Test123@example.com')
  end

  describe '#perform' do
    context 'primary address exists in duplicates' do
      it 'should destroy non-primary email address duplicates' do
        email_address_1.update_column(:primary, true)
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(2).to(1)
        expect(person.email_addresses).to contain_exactly(email_address_1)
      end
    end

    context 'primary address in duplicates does not exist' do
      let!(:email_address_0) { create(:email_address, person: person, primary: true) }

      it 'should destroy deleted address duplicates first' do
        email_address_1.update_column(:deleted, true)
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(3).to(2)
        expect(person.reload.email_addresses).to contain_exactly(email_address_0, email_address_2)
      end

      it 'should destroy historic address duplicates second' do
        email_address_1.update_column(:historic, true)
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(3).to(2)
        expect(person.reload.email_addresses).to contain_exactly(email_address_0, email_address_2)
      end

      it 'should destroy valid_values when false address duplicates third' do
        email_address_2.update_column(:valid_values, false)
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(3).to(2)
        expect(person.reload.email_addresses).to contain_exactly(email_address_0, email_address_1)
      end

      it 'should destroy remote_id when nil address duplicates fourth' do
        email_address_1.update_column(:remote_id, 'abc')
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(3).to(2)
        expect(person.reload.email_addresses).to contain_exactly(email_address_0, email_address_1)
      end

      it 'should destroy all duplicate addresses except one last' do
        expect do
          described_class.new.perform
        end.to change { person.email_addresses.count }.from(3).to(2)
        expect(person.reload.email_addresses).to contain_exactly(email_address_0, email_address_1)
      end
    end
  end
end
