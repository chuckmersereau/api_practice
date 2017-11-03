require 'rails_helper'

RSpec.describe OrganizationSerializer do
  let(:organization) { create(:organization, oauth_url: 'https://example.com') }
  subject { described_class.new(organization).as_json }

  describe '#oauth' do
    context 'organization is oauth capable' do
      it 'returns true' do
        expect(subject[:oauth]).to eq true
      end
    end
    context 'organization is not oauth capable' do
      let(:organization) { create(:organization, oauth_url: nil) }

      it 'returns false' do
        expect(subject[:oauth]).to eq false
      end
    end
  end
end
