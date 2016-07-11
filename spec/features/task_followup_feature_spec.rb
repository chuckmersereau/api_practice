require 'spec_helper'

Capybara.default_max_wait_time = 2
Capybara::Angular.default_max_wait_time = 10

describe 'Task Followup Dialog', type: :feature, js: true do
  include Capybara::Angular::DSL

  let(:user) { create(:user_with_account) }
  let(:contact) { create(:contact, account_list: user.account_lists[0], status: 'Contact for Appointment') }

  before :each do
    login(user)
    @task = create(:task, contacts: [contact], account_list: user.account_lists[0])
  end

  def visit_and_open_dialog(task)
    visit "/contacts/#{contact.id}"
    find('#tabs_tasks').click

    # various attempts at fixing this feature spec - still seems brittle!
    expect(page).to have_selector("#task_#{task.id}")

    find('.complete_task').click
    find('.ui-dialog')
  end

  def select_task_next_action(val)
    within('.ui-dialog') do
      find('#task_action_select select').find(:xpath, "option[@value='#{val}']").select_option
      click_on('Complete')
    end
  end

  it 'opens a dialog' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      expect(find('#task_result_select select')).to be_present
    end
  end

  it 'creates followup task for Call Again' do
    @task.update_attributes(tag_list: 'test')
    visit_and_open_dialog(@task)
    select_task_next_action('Call Again')
    expect do
      within('#complete_task_followup_modal') do
        click_on('Save')
      end
      expect(page).to have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    end.to change(contact.tasks, :count).by(1)
    expect(contact.tasks.where(activity_type: 'Call').last.tag_list.find).to include 'test'
  end

  it 'creates followup task for Appointment' do
    visit_and_open_dialog(@task)
    select_task_next_action('Appointment Scheduled')
    expect do
      within('#complete_task_followup_modal') do
        # check 'Create "Call" task' checkbox
        all('input[type="checkbox"]')[2].click
        find_button('Save').click
      end
      expect(page).to have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    end.to change(contact.tasks, :count).from(1).to(3)
    expect(contact.tasks.where(completed: false, activity_type: 'Appointment').count).to be 1
    expect(contact.tasks.where(completed: false, activity_type: 'Call').count).to be 1
    call_task = contact.tasks.find_by(completed: false, activity_type: 'Call')
    expect(call_task.start_at).to be < (DateTime.now + 2.days)
    expect(contact.reload.status).to eq 'Appointment Scheduled'
  end

  it 'does not change status for Appointment followup if status change box unchecked' do
    visit_and_open_dialog(@task)
    select_task_next_action('Appointment Scheduled')
    within('#complete_task_followup_modal') do
      # uncheck the update status checkbox (defaulted to checked)
      all('input[type="checkbox"]')[0].click
      find_button('Save').click
    end
    sleep(2)
    expect(contact.reload.status).to eq 'Contact for Appointment'
  end

  it 'adds Partner - Financial commitment' do
    visit_and_open_dialog(@task)
    select_task_next_action('Partner - Financial')
    expect do
      within('#complete_task_followup_modal') do
        select('Bi-Monthly', from: 'Commitment Frequency')
        fill_in('Commitment Amount', with: '100')
        all('input[type="checkbox"]').each do |cb|
          cb.click if cb.visible?
        end
        sleep(1)
        find_button('Save').click
      end
      expect(page).to have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    end.to change(contact.tasks, :count).from(1).to(3)
    expect(contact.tasks.where(completed: false, activity_type: 'Thank').count).to be 1
    expect(contact.reload.status).to eq 'Partner - Financial'
    expect(contact.send_newsletter).to eq 'Both'
    expect(contact.pledge_amount).to eq 100
    expect(contact.pledge_frequency.to_i).to eq 2
  end

  it 'updates Contact when Not Interested' do
    visit_and_open_dialog(@task)
    select_task_next_action('Not Interested')
    within('#complete_task_followup_modal') do
      find_button('Save').click
    end
    sleep(2)
    expect(contact.reload.status).to eq 'Not Interested'
  end
end
