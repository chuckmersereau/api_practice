require 'json_api_service'

class Api::V2::TasksController < Api::V2Controller
  def index
    authorize_index
    load_tasks
    render json: @tasks, meta: meta_hash(@tasks), include: include_params, fields: field_params
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
    @tasks = Task::Filterer.new(filter_params)
                           .filter(scope: task_scope, account_lists: account_lists)
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
           include: include_params,
           fields: field_params
  end

  def persist_task
    build_task
    authorize_task

    if save_task
      render_task
    else
      render_with_resource_errors(@task)
    end
  end

  def build_task
    @task ||= task_scope.build
    @task.assign_attributes(task_params)
  end

  def save_task
    @task.save(context: persistence_context)
  end

  def task_params
    params
      .require(:task)
      .permit(Task::PERMITTED_ATTRIBUTES)
  end

  def task_attributes
  end

  def authorize_task
    authorize(@task)
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def task_scope
    Task.where(account_list_id: account_lists.select(:id))
  end

  def permitted_sorting_params
    %w(completed_at start_at)
  end

  def permitted_filters
    @permitted_filters ||=
      Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym) +
      Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym) +
      [:account_list_id]
  end
end
