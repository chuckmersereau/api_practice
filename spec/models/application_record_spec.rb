require 'rails_helper'
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
        ["is not equal to the current value in the database (#{contact.updated_at.utc.iso8601})"]
      )
      expect(contact.reload.name).not_to eq('New Name')
    end

    it 'allows the update to take place when the resource is not outdated' do
      contact.assign_attributes(name: 'New Name', updated_in_db_at: contact.updated_at)
      contact.save(context: :update_from_controller)

      expect(contact.errors[:updated_in_db_at]).to be_empty
      expect(contact.reload.name).to eq('New Name')
    end

    it 'will ignore the updated_in_db_at requirements if #overwrite is true' do
      contact.overwrite = true
      expect(contact.valid?(:update_from_controller)).to be_truthy
      contact.updated_in_db_at = 2.weeks.ago
      expect(contact.valid?(:update_from_controller)).to be_truthy
    end

    it 'will NOT ignore the updated_in_db_at requirements if #overwrite is something OTHER than true' do
      contact.overwrite = 'peanut butter'
      expect(contact.valid?(:update_from_controller)).to eq false
      contact.updated_in_db_at = 2.weeks.ago
      expect(contact.valid?(:update_from_controller)).to eq false

      # correct expectations
      contact.updated_in_db_at = contact.updated_at
      expect(contact.valid?(:update_from_controller)).to eq true
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

  describe '::find_by_uuid_or_raise' do
    context 'when a record exists by that UUID' do
      let!(:contact) { create(:contact) }
      let!(:uuid)    { contact.uuid }

      it 'find that record by the UUID' do
        expect(Contact.find_by_uuid_or_raise!(uuid)).to eq contact
      end
    end

    context "when a record doesn't exist by a UUID" do
      let(:uuid) { SecureRandom.uuid }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { Contact.find_by_uuid_or_raise!(uuid) }
          .to raise_error(ActiveRecord::RecordNotFound)
          .with_message("Couldn't find Contact with 'uuid'=#{uuid}")
      end
    end

    context 'when the UUID passed is `nil`' do
      let(:uuid) { nil }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { Contact.find_by_uuid_or_raise!(uuid) }
          .to raise_error(ActiveRecord::RecordNotFound)
          .with_message("Couldn't find Contact with 'uuid'=#{uuid}")
      end
    end
  end
end
