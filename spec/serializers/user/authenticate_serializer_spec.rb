require 'rails_helper'

describe User::AuthenticateSerializer do
  let(:user) { create(:user) }
  let(:resource) { User::Authenticate.new(user: user) }

  subject { User::AuthenticateSerializer.new(resource).as_json }

  it { should include :json_web_token }

  describe 'json_web_token' do
    it 'delegates to user' do
      expect(subject[:json_web_token]).to eq resource.json_web_token
    end
  end
end
