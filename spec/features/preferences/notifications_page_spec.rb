require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 5

describe 'notifications preferences page', js: true do
  #include Capybara::Angular::DSL
  let!(:user) do
    user = create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  #let!(:notification_preferences) { PreferenceSet.new(user: user, account_list: user.account_lists.first, notification_settings: 'default') }

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 1.5
    all('aside#leftmenu li')[1].click
    sleep 1
  end

  it 'toggles email for partner missed a gift' do

    NotificationType.all.each_with_index do |type, index|
      actions = index.even? ? %w(task) : %w(task email)
      user.account_lists.first.notification_preferences.new(notification_type_id: type.id, actions: actions)
    end

    login_and_visit

    form_group = all('.panel .list-group .form-group')[0]
    firstVal = form_group.all('input')[0].checked?
    form_group.all('input')[0].click
    click_button('Save Preferences')
    expect( expect(first('.alert')).to have_content 'Preferences saved successfully' )
    expect( form_group.all('input')[0] ).to be_checked if !firstVal
    expect( form_group.all('input')[0] ).to_not be_checked if firstVal
  end


end
