require 'spec_helper'
require 'securerandom'

describe ApplicationRecord do
  let(:contact) { create(:contact, uuid: nil) }
  let(:given_uuid) { SecureRandom.uuid }
  let(:contact_with_uuid) { create(:contact, uuid: given_uuid) }

  describe '#before_save' do
    it 'generates a new uuid when the uuid field is set to nil' do
      expect(contact.uuid.length).to eq(36)
    end

    it 'does not generate a uuid when the uuid field is given' do
      expect(contact_with_uuid.uuid).to eq(given_uuid)
    end
  end
end
