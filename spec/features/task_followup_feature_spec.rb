require 'spec_helper'

describe 'Task Followup Dialog', type: :feature, js: true do
  let(:user) { create(:user_with_account) }
  let(:contact) { create(:contact, account_list: user.account_lists[0], status: 'Contact for Appointment') }

  before :each do
    login(user)
    @task = create(:task, contacts: [contact], account_list: user.account_lists[0])
  end

  def visit_and_open_dialog(task)
    visit "/contacts/#{contact.id}"
    first('#tabs_tasks').click

    wait_for_ajax
    sleep 1

    within("#task_#{task.id}") do
      first('.complete_task').click
    end
  end

  def select_task_next_action(val)
    within('.ui-dialog') do
      first('#task_action_select select').find(:xpath, "option[@value='#{val}']").select_option
      click_on('Complete')
    end
  end

  it 'opens a dialog' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      expect(first('#task_result_select select')).to be_present
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
    expect(contact.tasks.where(activity_type: 'Call').last.tag_list.first).to include 'test'
  end

  it 'creates followup task for Appointment' do
    visit_and_open_dialog(@task)
    select_task_next_action('Appointment Scheduled')
    expect do
      within('#complete_task_followup_modal') do
        # check 'Create "Call" task' checkbox
        all('input[type="checkbox"]')[2].trigger('click')
        find_button('Save').trigger('click')
      end
      expect(page).to have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    end.to change(contact.tasks, :count).from(1).to(3)
    expect(contact.tasks.where(completed: false, activity_type: 'Appointment').count).to be 1
    expect(contact.tasks.where(completed: false, activity_type: 'Call').count).to be 1
    call_task = contact.tasks.where(completed: false, activity_type: 'Call').first
    expect(call_task.start_at).to be < (DateTime.now + 2.days)
    expect(contact.reload.status).to eq 'Appointment Scheduled'
  end

  it 'does not change status for Appointment followup if status change box unchecked' do
    visit_and_open_dialog(@task)
    select_task_next_action('Appointment Scheduled')
    within('#complete_task_followup_modal') do
      # uncheck the update status checkbox (defaulted to checked)
      all('input[type="checkbox"]')[0].trigger('click')
      find_button('Save').trigger('click')
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
          cb.trigger('click') if cb.visible?
        end
        sleep(1)
        find_button('Save').trigger('click')
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
      find_button('Save').trigger('click')
    end
    sleep(2)
    expect(contact.reload.status).to eq 'Not Interested'
  end
end
