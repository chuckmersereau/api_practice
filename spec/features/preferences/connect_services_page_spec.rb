require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 5

describe 'connect services page', js: true do
  let!(:user) do
    user = create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
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
