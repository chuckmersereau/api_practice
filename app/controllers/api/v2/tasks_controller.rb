require 'json_api_service'

class Api::V2::TasksController < Api::V2Controller
  PERMIT_MULTIPLE_SORTING_PARAMS = true

  def index
    authorize_index
    load_tasks
    render json: Api::V2::TasksPreloader.new(include_params, field_params).preload(@tasks),
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
    @task.deleted_by = current_user
    @task.destroy
    head :no_content
  end

  def load_tasks
    @tasks = Task::Filterer.new(filter_params)
                           .filter(scope: task_scope, account_lists: account_lists)
                           .page(page_number_param)
                           .per(per_page_param)
    order_tasks
  end

  def order_tasks
    @tasks = @tasks.reorder(sorting_param)
    @tasks = @tasks.select(
      <<~SQL
        "activities".*,
        CASE WHEN "activities"."completed" != true AND "activities"."start_at" < now()
        THEN "activities"."start_at" END AS "overdue"
      SQL
    ) if sorting_param == default_sort_param
    @tasks = @tasks.order(Task.arel_table[:created_at].asc)
  end

  def load_task
    @task ||= Task.find(params[:id])
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
    Task.where(account_list: account_lists.collect(&:id))
  end

  def permitted_sorting_params
    %w(start_at completed_at)
  end

  def default_sort_param
    <<~SQL
      "overdue" DESC NULLS LAST,
      "activities"."completed_at" DESC,
      "activities"."start_at" ASC NULLS LAST
    SQL
  end

  def permitted_filters
    @permitted_filters ||= reversible_filters_including_filter_flags + [:account_list_id, :any_tags]
  end

  def reversible_filters
    Task::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym) +
      Task::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym)
  end

  def reversible_filters_including_filter_flags
    reversible_filters.map do |reversible_filter|
      [reversible_filter, "reverse_#{reversible_filter}".to_sym]
    end.flatten
  end

  def excluded_filter_keys_from_casting_validation
    [:date_range]
  end
end
