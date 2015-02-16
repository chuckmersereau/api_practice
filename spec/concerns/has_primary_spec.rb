require 'spec_helper'

describe HasPrimary do
  context '#ensure_only_one_primary? for person and email addresses (responds to :historic)' do
    let(:person) { create(:person) }
    let(:email1) { create(:email_address, email: 'a@t.co', primary: true) }
    let(:email2) { create(:email_address, email: 'b@t.co', primary: false) }

    before do
      person.email_addresses << email1
      person.email_addresses << email2
    end

    it 'leaves the existing primary one if one is specified' do
      email1.send(:ensure_only_one_primary)
      expect(email1.reload.primary).to be_true
      expect(email2.reload.primary).to be_false
    end

    it 'updates one of the items to become primary if none are' do
      email1.update_column(:primary, false)
      email1.send(:ensure_only_one_primary)
      email1.reload
      email2.reload
      expect(email1.primary || email2.primary).to be_true
      expect(email1.primary && email2.primary).to be_false
    end

    it 'makes it so that only one of the items can be primary' do
      email2.update_column(:primary, true)
      email2.send(:ensure_only_one_primary)
      email1.reload
      email2.reload
      expect(email1.primary || email2.primary).to be_true
      expect(email1.primary && email2.primary).to be_false
    end

    it 'sets historic items to not primary' do
      email1.update_column(:historic, true)
      email1.send(:ensure_only_one_primary)
      expect(email1.reload.primary).to be_false
      expect(email2.reload.primary).to be_true

      email2.update_column(:historic, true)
      email2.send(:ensure_only_one_primary)
      expect(email1.reload.primary).to be_false
      expect(email2.reload.primary).to be_false
    end
  end

  context '#ensure_only_one_primary? case for person and email addresses (does not respond to :historic)' do
    let(:contact) { create(:contact) }
    let(:person1) { create(:person) }
    let(:person2) { create(:person) }
    let!(:contact_person1) { create(:contact_person, contact: contact, person: person1, primary: true) }
    let!(:contact_person2) { create(:contact_person, contact: contact, person: person2, primary: false) }

    it 'leaves the existing primary one if one is specified' do
      contact_person1.send(:ensure_only_one_primary)
      expect(contact_person1.reload.primary).to be_true
      expect(contact_person2.reload.primary).to be_false
    end

    it 'updates one of the items to become primary if none are' do
      contact_person1.update_column(:primary, false)
      contact_person1.send(:ensure_only_one_primary)
      contact_person1.reload
      contact_person2.reload
      expect(contact_person1.primary || contact_person2.primary).to be_true
      expect(contact_person1.primary && contact_person2.primary).to be_false
    end

    it 'makes it so that only one of the items can be primary' do
      contact_person2.update_column(:primary, true)
      contact_person2.send(:ensure_only_one_primary)
      contact_person1.reload
      contact_person2.reload
      expect(contact_person1.primary || contact_person2.primary).to be_true
      expect(contact_person1.primary && contact_person2.primary).to be_false
    end
  end
end
