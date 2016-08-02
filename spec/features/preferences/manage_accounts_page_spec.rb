require 'spec_helper'

Capybara.default_max_wait_time = 5

describe 'personal accounts preferences', js: true do
  setup do
    page.driver.browser.url_blacklist = ['http://use.typekit.net']
  end
  
  let!(:user) do
    create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 4
    all('aside#leftmenu li')[4].click
    sleep 1.5
  end

  it 'Accounts display and delete correctly' do
    create(:user, account_lists: user.account_lists)
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
  end

  it 'Accounts merges correctly' do
    expect(user.account_lists.length).to be 2

    login_and_visit

    current_panel = all('.panel-group .panel')[1]
    current_panel.click
    sleep 0.5
    current_panel.find('.chosen-container').click
    expect(current_panel.all('.chosen-results li').length).to eq 1
    current_panel.all('.chosen-results li')[0].click
    click_button('Merge')
    sleep 1
    expect(page).to have_content 'You only have access to this account'
    expect(current_panel.all('.form-group').length).to be 0
    user.reload
    expect(user.account_lists.length).to be 1
  end

  it 'Accounts merges correctly in spouse tab' do
    expect(user.account_lists.length).to be 2

    login_and_visit

    current_panel = all('.panel-group .panel')[2]
    current_panel.click
    sleep 0.5
    current_panel.find('.chosen-container').click
    sleep 0.5
    expect(current_panel.all('.chosen-results li').length).to eq 1
    sleep 0.5
    current_panel.find('.chosen-results li').click
    current_panel.all('div.well')[1].find('button.btn').click
    sleep 1
    expect(page).to have_content 'You only have access to this account'
    expect(current_panel.all('.chosen-container').length).to be 0
    user.reload
    expect(user.account_lists.length).to be 1
  end

  it 'Invite e-mail correctly sends in spouse tab' do
    login_and_visit

    current_panel = all('.panel-group .panel')[2]
    current_panel.click
    sleep 0.5
    fill_in('email', with: 'foo@bar.com')
    expect(AccountListInvite).to receive(:send_invite).with(user, user.account_lists.find_by(name: 'Charles Spurgeon'), 'foo@bar.com')
    click_button('Share Account')
    sleep 1
  end
end
