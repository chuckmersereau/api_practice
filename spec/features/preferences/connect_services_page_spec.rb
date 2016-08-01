require 'spec_helper'

Capybara.default_max_wait_time = 2

describe 'internal services preferences', js: true do
  let!(:user) do
    create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 1.5
    all('aside#leftmenu li')[3].click
    sleep 1.5
  end

  it 'Key/Relay panel shows and deletes correctly' do
    create(:key_account, person: user, email: 'foo@bar.com')
    user_key_accounts = user.key_accounts
    expect(user_key_accounts.length).to be 2

    login_and_visit

    all('.panel-group .panel')[0].click
    expect(all('.network_connections').length).to eq 2
    all('.network_connections')[0].find('.delete').click
    sleep 3
    user_key_accounts.reload
    expect(user_key_accounts.length).to be 1
  end

  it 'organization accounts show and deletes correctly' do
    create(:organization_account, person: user)
    user_organization_accounts = user.organization_accounts
    expect(user_organization_accounts.length).to be 2

    login_and_visit

    all('.panel-group .panel')[1].click
    expect(all('.network_connections').length).to eq 2
    all('.network_connections')[0].find('.delete').click
    sleep 3
    user_organization_accounts.reload
    expect(user_organization_accounts.length).to be 1
  end
end

describe 'external services preferences', js: true do
  let!(:user) do
    create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 3
    all('aside#leftmenu li')[3].click
    sleep 1.5
  end

  it 'Google accounts shows and deletes' do
    create(:google_account, person: user, email: 'foo@bar.com', refresh_token: nil)

    user_google_accounts = user.google_accounts
    expect(user_google_accounts.length).to be 1

    login_and_visit

    all('.panel-group .panel')[2].click
    sleep 1
    expect(all('.account_single').length).to eq 1
    all('.account_single')[0].find('.delete').click
    sleep 2
    user_google_accounts.reload
    expect(user_google_accounts.length).to be 0
  end
end
