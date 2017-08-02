require 'rails_helper'

describe Contact::Duplicate do
  let(:first_contact)  { create(:contact) }
  let(:second_contact) { create(:contact) }
  let(:third_contact)  { create(:contact) }
  let(:fourth_contact) { create(:contact) }

  let(:duplicate) { described_class.new(first_contact, second_contact) }

  describe '#shares_an_id_with?' do
    it 'returns true if dup_people any member person in common' do
      expect(
        described_class.new(third_contact, fourth_contact).shares_an_id_with?(duplicate)
      ).to be_falsy
      expect(
        described_class.new(second_contact, fourth_contact).shares_an_id_with?(duplicate)
      ).to be_truthy
      expect(
        described_class.new(first_contact, second_contact).shares_an_id_with?(duplicate)
      ).to be_truthy
    end
  end
end
