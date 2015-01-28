require 'spec_helper'

describe 'Task Followup Dialog', type: :feature, js: true do
  let(:user) { create(:user_with_account) }
  let(:contact) { create(:contact, account_list: user.account_lists[0]) }

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
      first('#task_result_select select').find(:xpath, 'option[1]').select_option
    end
  end

  it 'creates followup task for Call Again' do
    visit_and_open_dialog(@task)
    within('.ui-dialog') do
      first('#task_result_select select').find(:xpath, 'option[2]').select_option
      click_on('Complete')
    end
    # this is needed to keep the server alive so the js api can reach it
    save_screenshot(nil)
  end
end
