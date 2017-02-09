require 'rails_helper'

RSpec.describe User::Authenticate, type: :model do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:resource) { User::Authenticate.new(user: user) }

  it 'initializes' do
    expect(resource).to be_a User::Authenticate
    expect(resource.user).to eq user
  end

  describe '#json_web_token' do
    subject { resource.json_web_token }

    it 'returns a json_web_token which decodes to the same user id' do
      expect(subject).to be_present
      expect(User.find(JsonWebToken.decode(subject)['user_id']).id).to eq user.id
    end
  end
end
