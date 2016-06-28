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
    create(:contact, account_list: user.account_lists.first, name: 'Apostle John')
    create(:contact, account_list: user.account_lists.first, name: 'Apostle Paul')
    create(:contact, account_list: user.account_lists.first, name: 'Simon Peter')
    create_list(:contact, 50, account_list: user.account_lists.first)
  end

  it 'displays a list of contacts' do
    visit '/contacts'
    expect(find('.pagination')).to have_content '2'
    expect(all('contact').length).to eq 25
    click_on('Next')
    expect(all('contact').length).to eq 25
    click_on('Next')
    expect(all('contact').length).to eq 3
  end

  it 'correctly filters contacts through search' do
    visit '/contacts'
    fill_in('contact_name', with: 'Apostle')
    expect(all('contact').length).to eq 2
  end
end
