require 'rails_helper'

describe JsonWebToken do
  let(:payload) { { 'user_uuid' => SecureRandom.uuid } }
  let(:token)   { JsonWebToken.encode(payload) }

  context '.encode' do
    it 'returns encoded token' do
      expect(token.length).to be > 15
    end
  end

  context '.decode' do
    it 'decodes' do
      expect(JsonWebToken.decode(token)).to eq(payload)
    end

    it 'escapes any JWT::Decode errors and returns nil' do
      expect(JWT).to receive(:decode).and_raise(JWT::DecodeError)
      expect(JsonWebToken.decode(token)).to eq(nil)
    end
  end
end
