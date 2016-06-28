require 'spec_helper'
require 'capybara/rspec'
require 'capybara/angular'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 10

describe 'create new contact', js: true do
  include Capybara::Angular::DSL

  before :each do
    user = create(:user_with_account)
    login(user)
    create(:contact, account_list: user.account_lists.first)
    create(:contact, account_list: user.account_lists.first)
    create(:contact, account_list: user.account_lists.first)
  end

  it 'displays a list of contacts' do
    visit '/contacts'
    expect(all('contact').length).to eq 3
  end
end
