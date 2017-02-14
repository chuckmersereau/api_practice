class Api::V2::Tasks::CommentsController < Api::V2Controller
  resource_type :comments

  def index
    authorize_index
    load_comments
    render json: @comments,
           meta: meta_hash(@comments),
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def show
    load_comment
    authorize_comment
    render_comment
  end

  def create
    persist_comment
  end

  def update
    load_comment
    authorize_comment
    persist_comment
  end

  def destroy
    load_comment
    authorize_comment
    destroy_comment
  end

  private

  def load_comments
    @comments = comments_scope.where(filter_params)
                              .reorder(sorting_param)
                              .page(page_number_param)
                              .per(per_page_param)
  end

  def load_comment
    @comment ||= comments_scope.find_by!(uuid: params[:id])
  end

  def destroy_comment
    @comment.destroy
    head :no_content
  end

  def build_comment
    @comment ||= comments_scope.build
    @comment.assign_attributes(comment_params)
  end

  def persist_comment
    build_comment
    authorize_comment

    if save_comment
      render_comment
    else
      render_with_resource_errors(@comment)
    end
  end

  def permitted_filters
    []
  end

  def activity_param_id
    params[:activity_id].presence || params[:task_id]
  end

  def load_activity
    @activity ||= Activity.find_by!(uuid: activity_param_id)
  end

  def comments_scope
    load_activity.comments
  end

  def authorize_index
    authorize(load_activity, :show?)
  end

  def authorize_comment
    authorize(load_comment)
  end

  def comment_params
    params.require(:comment)
          .permit(ActivityComment::PERMITTED_ATTRIBUTES)
  end

  def render_comment
    render json: @comment,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_comment
    @comment.save(context: persistence_context)
  end
end
