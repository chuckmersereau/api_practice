class Api::V2::Tasks::TagsController < Api::V2::ResourceController
  def create
    load_resource
    authorize @resource
    persist_resource(resource_params[:name]) do |tag_name|
      @resource.tag_list.add(tag_name)
    end
  end

  def destroy
    persist_resource(params[:tag_name]) do |tag_name|
      @resource.tag_list.remove(tag_name)
    end
  end

  private

  def persist_resource(tag_name)
    tag_error = TagValidator.new.validate(tag_name)
    if tag_error
      render_400_with_errors(tag_error)
    else
      yield(tag_name)
      @resource.save
      render json: @resource
    end
  end

  def load_resource
    @resource ||= Task.find(params[:task_id])
  end

  def resource_attributes
    [:name]
  end
end
