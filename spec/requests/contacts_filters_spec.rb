require 'spec_helper'

describe 'Contacts Filters' do
  describe 'GET /contacts' do
    it 'can filter on cities' do
      login(create(:user_with_account))

      get contacts_path(city: %w(foo bar))

      expect(response).to be_success
    end
  end
end
