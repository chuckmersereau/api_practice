require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 5

describe 'personal accounts preferences', js: true do
  let!(:user) do
    user = create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 1.5
    all('aside#leftmenu li')[4].click
    sleep 1.5
  end

  it 'Accounts display and delete correctly' do
    user_2 = create(:user, account_lists: user.account_lists)
    account_list = user.account_lists.first

    expect(account_list.users.length).to be 2

    login_and_visit

    all('.panel-group .panel')[0].click
    sleep 0.5
    expect(all('.account-users li').length).to eq 2
    click_button('Delete')
    sleep 1
    expect(all('.account-users li').length).to eq 1
    account_list.reload
    expect(account_list.users.length).to eq 1
    # all('.network_connections')[0].find('.delete').click
    # sleep 3
    # user_key_accounts.reload
    # expect(user_key_accounts.length).to be 1
  end
end
