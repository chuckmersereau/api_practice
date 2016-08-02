require 'spec_helper'

Capybara.default_max_wait_time = 5

describe 'personal preferences list', js: true do
  let!(:user) do
    user = create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon', time_zone: 'Wellington')
    second_account_list = create(:account_list, name: 'Account Bar')
    create(:account_list_user, user: user, account_list: second_account_list)
    create(:email_address, person: user, email: 'foo@bar.com')
    create(:phone_number, person: user)
    create(:address, addressable: user, primary_mailing_address: true)
    user
  end

  def login_and_visit
    login(user)
    sleep 4
    visit '/preferences/personal'
    sleep 4
  end

  def test_text_input_panel(i, old_val, new_val)
    login_and_visit

    panels = all('.panel')

    expect(panels[i].find('.pref-current')).to have_content old_val.upcase
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'

    panels[i].click

    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'CLOSE'
    expect(panels[i].find('input').value).to eq old_val

    panels[i].find('input').set(new_val)

    expect(panels[i].find('.pref-current')).to have_content new_val.upcase

    panels[i].find('button.btn').trigger('click')

    expect(find('.alert')).to have_content 'Preferences saved successfully'
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'
  end

  def test_dropdown_panel(i, old_val, new_val)
    login_and_visit

    panels = all('.panel')

    expect(panels[i].find('.pref-current')).to have_content old_val.upcase
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'

    panels[i].click

    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'CLOSE'
    expect(panels[i].find('.chosen-single')).to have_content old_val

    panels[i].find('.chosen-single').click
    panels[i].find('.chosen-search input').set(new_val)

    sleep 0.5

    panels[i].find('.chosen-results li').click

    sleep 1

    panels = all('.panel')
    expect(panels[i].find('.pref-current')).to have_content new_val.upcase

    panels[i].find('button.btn').trigger('click')

    expect(find('.alert')).to have_content 'Preferences saved successfully'
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'
  end

  def test_checkbox_panel(i)
    login_and_visit

    panels = all('.panel')

    expect(panels[i].find('.pref-current')).to have_content 'NO'
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'

    panels[i].click

    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'CLOSE'

    panels[i].find('label').click

    expect(panels[i].find('.pref-current')).to have_content 'YES'

    panels[i].find('button.btn').trigger('click')

    expect(find('.alert')).to have_content 'Preferences saved successfully'
    expect(panels[i].all('.panel-open-btn', visible: true)[0]).to have_content 'EXPAND'
  end

  it 'first name panel works correctly' do
    test_text_input_panel(0, 'Charles', 'Charlie')
  end

  it 'last name panel works correctly' do
    test_text_input_panel(1, 'Spurgeon', 'SpongeBob')
  end

  it 'email panel works correctly' do
    test_text_input_panel(2, 'foo@bar.com', 'ricky.baker@wilders.org')
  end

  it 'time zone works correctly' do
    test_dropdown_panel(3, 'Wellington', 'Jerusalem')
  end

  it 'locale works correctly' do
    test_dropdown_panel(4, '', 'Swedish')
  end

  it 'default account works correctly' do
    test_dropdown_panel(5, 'Charles Spurgeon', 'Account Bar')
  end

  it 'account name panel works correctly' do
    test_text_input_panel(6, 'Charles Spurgeon', 'Oxford Agape Conferences')
  end

  it 'home country works correctly' do
    test_dropdown_panel(7, '', 'Bhutan')
  end

  it 'monthly goal panel works correctly' do
    test_text_input_panel(8, '', '5000')
  end

  it 'early adopter panel works correctly' do
    test_checkbox_panel(9)
  end
end
