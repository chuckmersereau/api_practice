require 'spec_helper'

describe TasksController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
  end

  def valid_attributes
    FactoryGirl.build(:task, account_list: @account_list).attributes
      .except('id', 'type', 'created_at', 'updated_at',
              'account_list_id', 'activity_comments_count', 'completed_at')
  end

  describe 'GET index' do
    it 'assigns all tasks as @tasks' do
      task = @account_list.tasks.create! valid_attributes
      get :index, {}
      expect(assigns(:overdue)).to eq([task])
    end

    it 'filters by tag' do
      task1 = @account_list.tasks.create! valid_attributes.merge(tag_list: 'foo')
      @account_list.tasks.create! valid_attributes.merge(tag_list: 'bar')
      get :index, filters: { tags: 'foo' }
      expect(assigns(:overdue)).to eq([task1])
    end
  end

  describe 'GET new' do
    it 'assigns a new task as @task' do
      contact = create(:contact, account_list: @account_list)
      get :new, contact_id: contact.id
      expect(assigns(:task)).to be_a_new(Task)
      expect(assigns(:task).activity_contacts.first.contact).to eq contact
    end

    it 'includes contacts from old task' do
      old_task = create(:task, completed: true, account_list: @account_list)
      old_task.contacts << create(:contact)
      old_task.save
      get :new, from: old_task.id
      expect(assigns(:task).activity_contacts.any?).to be true
    end
  end

  describe 'GET edit' do
    it 'assigns the requested task as @task' do
      task = @account_list.tasks.create! valid_attributes
      get :edit,  id: task.to_param
      expect(assigns(:task)).to eq(task)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Task' do
        expect do
          post :create,  task: valid_attributes
        end.to change(@account_list.tasks, :count).by(1)
      end

      it 'assigns a newly created task as @task' do
        post :create,  task: valid_attributes
        expect(assigns(:task)).to be_a(Task)
        expect(assigns(:task)).to be_persisted
      end

      it 'redirects to the created task' do
        post :create,  task: valid_attributes
        expect(response).to redirect_to(tasks_path)
      end

      it 'creates many for a contact list' do
        c1 = create(:contact, account_list: @account_list)
        c2 = create(:contact, account_list: @account_list)
        expect do
          xhr :post, :create, task: valid_attributes, add_task_contact_ids: "#{c1.id}, #{c2.id}"
        end.to change { Task.count }.by 2
      end
    end

    describe 'with invalid params' do
      before do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Task).to receive(:save).and_return(false)
      end
      it 'assigns a newly created but unsaved task as @task' do
        post :create,  task: { subject: '' }
        expect(assigns(:task)).to be_a_new(Task)
        expect(response).to render_template('new')
      end
      it 'redirects when given add_task_contact_ids param' do
        xhr :post, :create,  task: { subject: '' }, add_task_contact_ids: [1]
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested task' do
        task = @account_list.tasks.create! valid_attributes
        # Assuming there are no other tasks in the database, this
        # specifies that the Task created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        expect_any_instance_of(Task).to receive(:update_attributes).with('subject' => 'foo')
        put :update,  id: task.to_param, task: { 'subject' => 'foo' }
      end

      it 'assigns the requested task as @task' do
        task = @account_list.tasks.create! valid_attributes
        put :update,  id: task.to_param, task: valid_attributes
        expect(assigns(:task)).to eq(task)
      end

      it 'redirects to the task' do
        task = @account_list.tasks.create! valid_attributes
        put :update,  id: task.to_param, task: valid_attributes
        expect(response).to redirect_to(tasks_path)
      end
    end

    describe 'PUT bulk_update' do
      it 'updates some tasks' do
        request.env['HTTP_REFERER'] = tasks_url
        t1 = create(:task, account_list: @account_list)
        t2 = create(:task, account_list: @account_list)
        put :bulk_update, bulk_task_update_ids: "#{t1.id},#{t2.id}", task: { subject: 'NewSub', 'start_at(1i)': 1.year.ago.year }
        expect(t1.reload.start_at.year).to eq 1.year.ago.year
      end
    end

    describe 'with invalid params' do
      it 'assigns the task as @task' do
        task = @account_list.tasks.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Task).to receive(:save).and_return(false)
        put :update,  id: task.to_param, task: { 'subject' => '' }
        expect(assigns(:task)).to eq(task)
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested task' do
      task = @account_list.tasks.create! valid_attributes
      request.env['HTTP_REFERER'] = tasks_url
      expect do
        delete :destroy,  id: task.to_param
      end.to change(@account_list.tasks, :count).by(-1)
    end

    it 'redirects to the tasks list' do
      task = @account_list.tasks.create! valid_attributes
      request.env['HTTP_REFERER'] = tasks_url
      delete :destroy,  id: task.to_param
      expect(response).to redirect_to(request.env['HTTP_REFERER'])
    end
  end

  describe 'DELETE bulk_destroy' do
    it 'destroys tasks' do
      t1 = create(:task, account_list: @account_list)
      t2 = create(:task, account_list: @account_list)
      expect do
        xhr :delete, :bulk_destroy, ids: [t1.id, t2.id]
      end.to change { Task.count }.by(-2)
    end
  end
end
