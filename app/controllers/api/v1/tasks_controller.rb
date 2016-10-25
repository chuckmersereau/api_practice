class Api::V1::TasksController < Api::V1::BaseController
  def index
    if params[:since]
      meta = { deleted: Version.where(item_type: 'Activity', event: 'destroy', related_object_type: 'AccountList', related_object_id: current_account_list.id)
                               .where('created_at > ?', Time.at(params[:since].to_i)).pluck(:item_id) }
    else
      meta = {}
    end

    meta.merge!(total: tasks.total_entries, from: correct_from(tasks),
                to: correct_to(tasks), page: page,
                total_pages: total_pages(tasks)) if tasks.respond_to?(:total_entries)

    render json: tasks,
           scope: { since: params[:since] },
           meta:  meta,
           callback: params[:callback]
  end

  def show
    task = tasks.find(params[:id])
    render json: task, callback: params[:callback]
  rescue
    render json: { errors: ['Not Found'] }, callback: params[:callback], status: :not_found
  end

  def update
    task = tasks.find(params[:id])
    if task.update_attributes(task_params)
      render json: task, callback: params[:callback]
    else
      render json: { errors: task.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  def create
    # task = tasks.new(task_params)
    # if task.save
    #   render json: task, callback: params[:callback], status: :created
    # else
    #   render json: { errors: task.errors.full_messages }, callback: params[:callback], status: :bad_request
    # end
    #
    # @task = current_account_list.tasks.new(task_params)

    @task = current_account_list.tasks.new(task_params)
    if params[:add_task_contact_ids].present?
      # First validate the task fields
      if @task.valid?
        # Create a copy of the task for each contact selected
        contacts = current_account_list.contacts.where(id: params[:add_task_contact_ids].split(','))
        contacts.each do |c|
          @task = current_account_list.tasks.create(task_params)
          ActivityContact.create(activity_id: @task.id, contact_id: c.id)
        end
        render nothing: true
      else
        render nothing: true, status: 400
      end
    elsif @task.save
      render nothing: true
    else
      render nothing: true, status: 400
    end
  end

  def destroy
    task = tasks.find(params[:id])
    task.destroy
    render json: task, callback: params[:callback]
  rescue
    render json: { errors: ['Not Found'] }, callback: params[:callback], status: :not_found
  end

  # yields {"total": ##,"uncompleted": ##,"overdue": ##}
  def count
    render json: {
      total: tasks.count,
      uncompleted: tasks.uncompleted.count,
      overdue: tasks.overdue.count,
      starred: tasks.uncompleted.starred.count,
      today: tasks.uncompleted.today.count,
      activity_types: tasks.where(completed: false).group(:activity_type).count
    },
           callback: params[:callback]
  end

  protected

  def tasks
    filtered_tasks = Task::Filterer.new(params[:filters]).filter(current_account_list.tasks, current_account_list)

    add_includes_and_order(filtered_tasks.includes(:contacts, :activity_comments, :people), order: params[:order])
  end

  def task_params
    # this segment is to support App version <= 1.4.1, remove weeks after next release
    if params[:task].present? && params[:task][:contacts_attributes].present? && params[:task][:activity_contacts_attributes].blank?
      params[:task][:activity_contacts_attributes] = params[:task].delete(:contacts_attributes).first
    end
    if params[:task].present? && params[:task][:activity_contacts_attributes].present?
      params[:task][:activity_contacts_attributes].map do |ac|
        ac[:contact_id] = ac.delete(:id) if ac.respond_to?(:each) && ac[:id].present? && ac[:contact_id].blank?
      end
    end

    params.require(:task).permit(Task::PERMITTED_ATTRIBUTES)
  end
end
