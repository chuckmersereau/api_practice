class Api::V2::Tasks::TagsController < Api::V2Controller
  def index
    authorize_index
    load_tags
    render json: @tags,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def create
    load_task
    authorize_task
    persist_tag(tag_params[:name]) do |tag_name|
      @task.tag_list.add(tag_name)
    end
  end

  def destroy
    load_task
    authorize_task
    destroy_tag
  end

  private

  def load_tags
    @tags ||= account_lists.map(&:activity_tags).flatten.uniq.sort_by(&:name)
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def destroy_tag
    persist_tag(params[:tag_name]) do |tag_name|
      @task.tag_list.remove(tag_name)
    end

    head :no_content
  end

  def persist_tag(tag_name)
    tag_error = TagValidator.new.validate(tag_name)

    if tag_error
      render_with_resource_errors(tag_error)
    else
      yield(tag_name)
      @task.save(context: persistence_context)

      render json: @task,
             status: success_status,
             include: include_params,
             fields: field_params
    end
  end

  def load_task
    @task ||= Task.find_by!(id: params[:task_id])
  end

  def authorize_task
    authorize @task
  end

  def permitted_filters
    [:account_list_id]
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
