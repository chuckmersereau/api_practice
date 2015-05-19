require 'spec_helper'

describe 'Add Task Dialog', type: :feature, js: true do
  let(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists[0]) }

  before :each do
    login(user)
    @task = build(:task, contacts: [contact], account_list: user.account_lists[0])
  end

  context 'new task dialog' do
    it 'creates a task in db' do
      visit '/'
      click_on 'Quick Add'
      click_on 'Add Task'
      expect do
        within('#edit_task_modal') do
          fill_in('Subject', with: @task.subject)
          select(@task.activity_type, from: 'Action')
          select(contact.name, from: 'Related To')
        end
        find_button('Save').trigger('click')
        expect(page).to have_css('#edit_task_modal', visible: false)
        sleep(1)
      end.to change(contact.tasks, :count).to(1)
    end
  end
end
