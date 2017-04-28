require 'json_api_service'

class Api::V2::TasksController < Api::V2Controller
  def index
    authorize_index
    load_tasks
    render json: @tasks.preload_valid_associations(include_associations)
      .preload(:tags, :comments, :people, :email_addresses, :phone_numbers),
           meta: meta_hash(@tasks),
           include: include_params,
           fields: field_params
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
                           .reorder(sorting_param || default_sorting)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_task
    @task ||= Task.find_by_uuid_or_raise!(params[:id])
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
    Task.where(account_list: account_lists)
  end

  def permitted_sorting_params
    %w(completed_at start_at)
  end

  def default_sorting
    'activities.completed ASC,activities.completed_at DESC,activities.start_at ASC NULLS LAST,activities.created_at ASC'
  end

  def permitted_filters
    @permitted_filters ||=
      Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym) +
      Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym) +
      [:account_list_id, :any_tags]
  end

  def excluded_filter_keys_from_casting_validation
    [:date_range, :no_date]
  end
end
