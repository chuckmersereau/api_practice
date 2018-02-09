require 'rails_helper'

RSpec.describe AccountListSerializer do
  let(:organization) { create(:organization) }
  let(:account_list) { create(:account_list, settings: { salary_organization_id: organization.id }) }

  let(:serializer) { AccountListSerializer.new(account_list) }
  let(:parsed_json_response) { JSON.parse(serializer.to_json) }

  context 'salary_organization' do
    it 'returns the id of the salary_organization_id' do
      expect(parsed_json_response['salary_organization']).to eq(organization.id)
    end
  end
end
