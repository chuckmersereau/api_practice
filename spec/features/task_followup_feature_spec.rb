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
    within("#task_#{task.id}") do
      first('.complete_task').click
    end
  end

  it 'opens a dialog' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      expect(first('#task_result_select select')).to be_present
    end
  end

  it 'creates followup task for Call Again' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      first('#task_action_select select').find(:xpath, 'option[1]').select_option
      click_on('Complete')
    end
    expect {
      within('#complete_task_followup_modal') do
        click_on('Save')
      end
      page.should have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    }.to change(contact.tasks, :count).by(1)

    # this is needed to keep the server alive so the js api can reach it
    save_screenshot(nil)
  end

  it 'creates followup task for Appointment' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      first('#task_action_select select').find(:xpath, 'option[2]').select_option
      click_on('Complete')
    end
    expect {
      within('#complete_task_followup_modal') do
        all('input').each do |cb|
          cb.trigger('click') if cb.visible?
        end
        find_button('Save').trigger('click')
      end
      expect(page).to have_css('#complete_task_followup_modal', visible: false)
      sleep(2)
    }.to change(contact.tasks, :count).from(1).to(3)
    expect(contact.tasks.where(completed: false, activity_type: 'Appointment').count).to be 1
    expect(contact.reload.status).to eq 'Appointment Scheduled'
    save_screenshot(nil)
  end

  it 'updates Contact when Not Interested' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      first('#task_action_select select').find(:xpath, 'option[7]').select_option
      click_on('Complete')
    end
    within('#complete_task_followup_modal') do
      find_button('Save').trigger('click')
    end
    sleep(2)
    expect(contact.reload.status).to eq 'Not Interested'
    save_screenshot(nil)
  end
end
