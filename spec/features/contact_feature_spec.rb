require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 10

describe 'contact list', js: true do
  include Capybara::Angular::DSL

  before :each do
    user = create(:user_with_account)
    login(user)

    contact_john = create(:contact_with_person, account_list: user.account_lists.first, name: 'Apostle John')
    create(:email_address, person: contact_john.people.first)
    create(:phone_number, person: contact_john.people.first)
    create(:address, addressable: contact_john, primary_mailing_address: true)
    create(:contact_with_person, account_list: user.account_lists.first, name: 'Apostle Paul')
    create(:contact_with_person, account_list: user.account_lists.first, name: 'Simon Peter', )
    create_list(:contact_with_person, 50, account_list: user.account_lists.first)
  end

  it 'displays a list of contacts with their details' do
    visit '/contacts'
    expect(all('contact').length).to eq 25
    expect(all('address')[0]).to have_content '123 Somewhere St'
    expect(all('address')[0]).to have_content 'Fremont'
  end

  it 'pagination works' do
    visit '/contacts'
    expect(find('.pagination')).to have_content '2'
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

  it 'correctly merges 2 accounts together' do
    visit '/contacts'
    contact_checkboxes = all('contact input')
    contact_checkboxes[0].set(true)
    contact_checkboxes[1].set(true)
    click_on('Merge')
    contact_names = all('contact .name a')
    contact_name_1 = contact_names[0].base.inner_html
    contact_name_2 = contact_names[1].base.inner_html
    merged_names = all('#merge_contact_names li')
    expect(merged_names[0]).to have_content contact_name_1
    expect(merged_names[1]).to have_content contact_name_2
    expect(find('#merge_modal .warning-text')).to have_content 'This action'
    click_button('Merge')
    visit '/contacts'
    expect(all('contact .people')[0]).to have_content contact_name_1
    expect(all('contact .people')[0]).to have_content contact_name_2
  end

  it 'correctly filters through contact information' do
    visit '/contacts'

    filter_lis = all('ul.filters li.filter_set')
    filter_lis[7].click
    filter_lis[7].all('input')[1].click
    expect(all('contact').length).to be (1)
    filter_lis[7].all('input')[0].click

    filter_lis[7].all('input')[10].click
    expect(all('contact').length).to be (1)


  end
end
