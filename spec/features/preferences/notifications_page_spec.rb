require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 5

describe 'notifications preferences page', js: true do
  #include Capybara::Angular::DSL
  let!(:user) do
    user = create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
    second_account_list = create(:account_list, name: 'Account Bar')
    create(:account_list_user, user: user, account_list: second_account_list)
    create(:email_address, person: user, email: 'foo@bar.com')
    create(:phone_number, person: user)
    create(:address, addressable: user, primary_mailing_address: true)
    user
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 2
    all('aside.leftmenu li')[1].click
    sleep 1
  end

  
end
