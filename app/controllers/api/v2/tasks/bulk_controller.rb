class Api::V2::Tasks::BulkController < Api::V2Controller
  skip_before_action :transform_id_param_to_uuid_attribute

  def update
    load_tasks
    authorize_tasks
    persist_tasks
  end

  def destroy
    load_tasks
    authorize_tasks
    destroy_tasks
  end

  private

  def load_tasks
    @tasks = task_scope.where(uuid: task_uuid_params).tap(&:first!)
  end

  def authorize_tasks
    bulk_authorize(@tasks)
  end

  def destroy_tasks
    @destroyed_tasks = @tasks.select(&:destroy)
    render json: BulkResourceSerializer.new(resources: @destroyed_tasks)
  end

  def task_uuid_params
    params.require(:data).collect { |hash| hash[:data][:id] }
  end

  def task_scope
    current_user.tasks
  end

  def persist_tasks
    build_tasks
    save_tasks
    render json: BulkResourceSerializer.new(resources: @tasks)
  end

  def save_tasks
    @tasks.each { |task| task.save(context: :update_from_controller) }
  end

  def build_tasks
    @tasks.each do |task|
      task.assign_attributes(
        task_params(params[:data][data_attribute_index(task)][:data][:attributes])
      )
    end
  end

  def data_attribute_index(task)
    params[:data].find_index { |task_data| task_data[:data][:id] == task.uuid }
  end

  def task_params(attributes)
    attributes ||= params.require(:data).require(:attributes)
    attributes.permit(Task::PERMITTED_ATTRIBUTES)
  end

  def permitted_filters
    []
  end
end
