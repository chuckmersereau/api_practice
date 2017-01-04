require 'spec_helper'
require 'securerandom'

describe ApplicationRecord do
  let(:contact) { create(:contact, uuid: nil) }

  describe '#before_save on create' do
    let(:given_uuid) { SecureRandom.uuid }
    let(:contact_with_uuid) { create(:contact, uuid: given_uuid) }

    it 'generates a new uuid when the uuid field is set to nil' do
      expect(contact.uuid.length).to eq(36)
    end

    it 'does not generate a uuid when the uuid field is given' do
      expect(contact_with_uuid.uuid).to eq(given_uuid)
    end
  end

  describe '#before_save on update_from_controller context' do
    it 'adds an error and does not save when resource is not given an updated_at field' do
      contact.assign_attributes(name: 'New Name')
      contact.save(context: :update_from_controller)

      expect(contact.errors[:updated_in_db_at]).to include(
        'has to be sent in the list of attributes in order to update resource'
      )
      expect(contact.reload.name).not_to eq('New Name')
    end

    it 'adds an error and does not save when resource is outdated' do
      contact.assign_attributes(name: 'New Name', updated_in_db_at: 2.weeks.ago)
      contact.save(context: :update_from_controller)

      expect(contact.errors[:updated_in_db_at]).to eq(
        ['is not equal to the current value in the database']
      )
      expect(contact.reload.name).not_to eq('New Name')
    end

    it 'allows the update to take place when the resource is not outdated' do
      contact.assign_attributes(name: 'New Name', updated_in_db_at: contact.updated_at)
      contact.save(context: :update_from_controller)

      expect(contact.errors[:updated_in_db_at]).to be_empty
      expect(contact.reload.name).to eq('New Name')
    end
  end

  describe '#updated_in_db_at=' do
    it 'accepts a Time' do
      new_time = 1.day.ago
      contact.updated_in_db_at = new_time
      expect(contact.updated_in_db_at).to be_a(Time)
      expect(contact.updated_in_db_at.iso8601).to eq(new_time.iso8601)
    end

    it 'accepts a String in ISO8601' do
      new_time = '2016-12-09T17:36:19Z'
      contact.updated_in_db_at = new_time
      expect(contact.updated_in_db_at).to be_a(Time)
      expect(contact.updated_in_db_at.iso8601).to eq(new_time)
    end
  end
end
