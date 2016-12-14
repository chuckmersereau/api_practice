class Api::V2::TasksController < Api::V2Controller
  def index
    authorize load_account_list, :show? if filter_params[:account_list_id]
    load_tasks
    render json: @tasks, meta: meta_hash(@tasks), include: include_params
  end

  def show
    load_task
    authorize_task
    render_task
  end

  def create
    persist_task
  end

  def update
    load_task
    authorize_task
    persist_task
  end

  def destroy
    load_task
    authorize_task
    destroy_task
  end

  private

  def destroy_task
    @task.destroy
    head :no_content
  end

  def load_tasks
    @tasks = task_scope.where(filter_params)
                       .reorder(sorting_param)
                       .page(page_number_param)
                       .per(per_page_param)
  end

  def load_task
    @task ||= Task.find_by!(uuid: params[:id])
  end

  def render_task
    render json: @task,
           status: success_status,
           include: include_params
  end

  def persist_task
    build_task
    authorize_task

    if save_task
      render_task
    else
      render_400_with_errors(@task)
    end
  end

  def build_task
    @task ||= task_scope.build
    @task.assign_attributes(task_params)
  end

  def save_task
    @task.save
  end

  def task_params
    params.require(:data).require(:attributes).permit(Task::PERMITTED_ATTRIBUTES)
  end

  def authorize_task
    authorize @task
  end

  def task_scope
    Task.that_belong_to(current_user)
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    [:account_list_id]
  end
end
