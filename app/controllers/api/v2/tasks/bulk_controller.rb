class Api::V2::Tasks::BulkController < Api::V2Controller
  skip_before_action :transform_id_param_to_uuid_attribute
  def update
    load_tasks_to_update
    authorize_tasks_to_update
    persist_tasks_to_update
  end

  private

  def load_tasks_to_update
    @tasks = task_scope.where(uuid: task_ids_from_update_list).tap(&:first!)
  end

  def authorize_tasks_to_update
    @tasks.each { |task| authorize task }
  end

  def persist_tasks_to_update
    build_tasks_to_update
    bulk_save_tasks
    render json: BulkUpdateSerializer.new(resources: @tasks)
  end

  def bulk_save_tasks
    @tasks.each { |task| task.save(context: :update_from_controller) }
  end

  def build_tasks_to_update
    @tasks.each do |task|
      task.assign_attributes(
        task_params(params[:data][data_attribute_index(task)][:attributes])
      )
    end
  end

  def data_attribute_index(task)
    params[:data].find_index { |task_data| task_data[:id] == task.uuid }
  end

  def task_ids_from_update_list
    params[:data].map { |task_param| task_param['id'] }
  end

  def task_scope
    Task.where(account_list: account_lists)
  end

  def task_params(attributes)
    attributes ||= params.require(:data).require(:attributes)

    attributes.permit(Task::PERMITTED_ATTRIBUTES)
  end
end
