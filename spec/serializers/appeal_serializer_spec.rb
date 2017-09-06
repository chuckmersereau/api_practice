require 'rails_helper'

RSpec.describe AppealSerializer do
  let!(:appeal) { create(:appeal) }
  let!(:donation_one) { create(:donation, currency: 'CAD').tap { |donation| appeal.donations << donation } }
  let!(:donation_two) { create(:donation, currency: 'ZAR').tap { |donation| appeal.donations << donation } }

  let(:serializer) { AppealSerializer.new(appeal) }
  let(:parsed_json_response) { JSON.parse(serializer.to_json) }

  describe '#currencies' do
    it 'returns all currencies from the donations' do
      expect(parsed_json_response['currencies']).to match_array(%w(CAD ZAR))
    end
  end

  describe '#total_currency' do
    it 'returns the account list salary currency' do
      expect(parsed_json_response['total_currency']).to eq(appeal.account_list.salary_currency)
    end
  end
end
