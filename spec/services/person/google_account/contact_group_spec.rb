require 'rails_helper'

RSpec.describe Person::GoogleAccount::ContactGroup do
  let(:api_contact_groups) do
    [
      OpenStruct.new(
        id: 'contact_group_id_0',
        title: 'contact_group_title_0',
        updated: Date.today
      ),
      OpenStruct.new(
        id: 'contact_group_id_1',
        title: 'contact_group_title_1',
        updated: Date.today
      )
    ]
  end

  let(:contact_groups) do
    [
      described_class.new(
        id: 'contact_group_id_0',
        title: 'contact_group_title_0',
        uuid: 'contact_group_id_0',
        created_at: Date.today,
        updated_at: Date.today
      ),
      described_class.new(
        id: 'contact_group_id_1',
        title: 'contact_group_title_1',
        uuid: 'contact_group_id_1',
        created_at: Date.today,
        updated_at: Date.today
      )
    ]
  end

  describe '.from_groups' do
    it 'should create collection of instances' do
      expect(described_class.from_groups(api_contact_groups)[0].to_json).to eq(contact_groups[0].to_json)
      expect(described_class.from_groups(api_contact_groups)[1].to_json).to eq(contact_groups[1].to_json)
    end
  end
end
