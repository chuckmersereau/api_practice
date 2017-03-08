require 'rails_helper'

describe Person::Duplicate do
  context '#minimum_person_id' do
    let(:person) { build(:person, id: 1) }
    let(:dup_person) { build(:person, id: 2) }
    let(:contact) { build(:contact) }
    let(:duplicate) { described_class.new(person: person, dup_person: dup_person, shared_contact: contact) }

    it 'returns the minimum id between person_id and dup_person_id' do
      expect(duplicate.minimum_person_id).to eq(1)
    end
  end
end
