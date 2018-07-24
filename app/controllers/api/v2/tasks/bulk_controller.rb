class Api::V2::Tasks::BulkController < Api::V2::BulkController
  resource_type :tasks

  def create
    build_empty_tasks
    persist_tasks
  end

  def update
    load_tasks
    persist_tasks
  end

  def destroy
    load_tasks
    authorize_tasks
    destroy_tasks
  end

  private

  def load_tasks
    @tasks = task_scope.where(id: task_id_params).tap(&:first!)
  end

  def authorize_tasks
    bulk_authorize(@tasks)
  end

  def destroy_tasks
    @destroyed_tasks = @tasks.select(&:destroy)
    render_tasks(@destroyed_tasks)
  end

  def task_id_params
    params
      .require(:data)
      .collect { |hash| hash[:task][:id] }
  end

  def task_scope
    current_user.tasks
  end

  def persist_tasks
    build_tasks
    authorize_tasks
    save_tasks
    render_tasks(@tasks)
  end

  def render_tasks(tasks)
    render json: BulkResourceSerializer.new(resources: tasks),
           include: include_params,
           fields: field_params
  end

  def save_tasks
    @tasks.each { |task| task.save(context: persistence_context) }
  end

  def build_empty_tasks
    @tasks = params.require(:data).map { |data| Task.new(id: data['task']['id']) }
  end

  def build_tasks
    @tasks.each do |task|
      task_index = data_attribute_index(task)
      attributes = params.require(:data)[task_index][:task]
      task.assign_attributes(
        task_params(attributes)
      )
    end
  end

  def data_attribute_index(task)
    params
      .require(:data)
      .find_index { |task_data| task_data[:task][:id] == task.id }
  end

  def task_params(attributes)
    attributes ||= params.require(:task)
    attributes.permit(Task::PERMITTED_ATTRIBUTES)
  end
end
