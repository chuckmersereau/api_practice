class Api::V2::Tasks::TagsController < Api::V2Controller
  def create
    load_task
    authorize_task
    persist_resource(task_params[:name]) do |tag_name|
      @task.tag_list.add(tag_name)
    end
  end

  def destroy
    load_task
    authorize_task
    persist_resource(params[:tag_name]) do |tag_name|
      @task.tag_list.remove(tag_name)
    end
  end

  private

  def persist_resource(tag_name)
    tag_error = TagValidator.new.validate(tag_name)
    if tag_error
      render_400_with_errors(tag_error)
    else
      yield(tag_name)
      @task.save
      render json: @task
    end
  end

  def load_task
    @task ||= Task.find(params[:task_id])
  end

  def authorize_task
    authorize @task
  end

  def task_params
    params.require(:data).require(:attributes).permit(:name)
  end
end
