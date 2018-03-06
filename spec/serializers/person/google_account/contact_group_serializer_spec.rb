require 'rails_helper'

RSpec.describe Person::GoogleAccount::ContactGroupSerializer do
  let(:contact_group) do
    Person::GoogleAccount::ContactGroup.new(
      id: 'contact_group_id_0',
      title: 'System Group: My Family',
      created_at: Date.today,
      updated_at: Date.today
    )
  end

  subject { described_class.new(contact_group).as_json }

  describe '#title' do
    it 'returns title without System Group' do
      expect(subject[:title]).to eq('My Family')
    end
  end

  describe '#tag' do
    it 'returns tag without System Group' do
      expect(subject[:tag]).to eq('my-family')
    end
  end
end
