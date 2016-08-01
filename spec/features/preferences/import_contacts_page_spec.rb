require 'spec_helper'

Capybara.default_max_wait_time = 2

describe 'import contacts page', js: true, sidekiq: 'acceptance' do
  let!(:user) do
    create(:user_with_account, first_name: 'Charles', last_name: 'Spurgeon')
  end

  before do
    Sidekiq::Testing.inline!
    login_and_visit
  end

  def login_and_visit
    login(user)
    visit '/preferences/personal'
    sleep 1.5
    all('aside#leftmenu li')[2].click
    sleep 1.5
  end

  it 'imports tnt contacts' do
    all('.panel-group .panel')[0].click
    attach_file('import_file', './spec/fixtures/tnt/tnt_export_new.xml')
    all('.panel-group .panel')[0].find('input.btn').trigger('click')
    sleep 5
    expect(Contact.all.length).to be > 0
  end

  it 'imports csv contacts' do
    all('.panel-group .panel')[1].click
    attach_file('import_file', './spec/fixtures/sample_csv_to_import.csv')
    click_button('Preview Import')
    sleep 5
    expect(page).to have_content 'John and Jane'
    expect(page).to have_content 'John Doe'
    expect(page).to have_content 'Jane Doe'
  end
end
