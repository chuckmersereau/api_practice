require 'rails_helper'

describe Person::Duplicate do
  let(:first_person) { create(:person) }
  let(:second_person) { create(:person) }
  let(:third_person) { create(:person) }
  let(:fourth_person) { create(:person) }
  let(:contact) { create(:contact) }
  let(:duplicate) { described_class.new(person: first_person, dup_person: second_person, shared_contact: contact) }

  describe '#shares_an_id_with?' do
    it 'returns true if dup_people any member person in common' do
      expect(
        described_class.new(person: third_person, dup_person: fourth_person, shared_contact: contact).shares_an_id_with?(duplicate)
      ).to be_falsy
      expect(
        described_class.new(person: second_person, dup_person: fourth_person, shared_contact: contact).shares_an_id_with?(duplicate)
      ).to be_truthy
      expect(
        described_class.new(person: first_person, dup_person: second_person, shared_contact: contact).shares_an_id_with?(duplicate)
      ).to be_truthy
    end
  end
end
