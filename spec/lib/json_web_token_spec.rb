require 'spec_helper'

describe JsonWebToken do
  let(:payload) { { 'user_id' => 1 } }
  let(:token) { JsonWebToken.encode(payload) }
  context '.encode' do
    it 'returns encoded token' do
      expect(token.length).to be > 15
    end
  end

  context '.decode' do
    it 'decodes' do
      expect(JsonWebToken.decode(token)).to eq(payload)
    end
  end
end
