class Api::V2::BackgroundBatchesController < Api::V2Controller
  def index
    load_background_batches
    render json: @background_batches.preload_valid_associations(include_associations),
           meta: meta_hash(@background_batches),
           include: include_params,
           fields: field_params
  end

  def show
    load_background_batch
    authorize_background_batch
    render_background_batch
  end

  def create
    binding.pry
    persist_background_batch
  end

  def destroy
    load_background_batch
    authorize_background_batch
    destroy_background_batch
  end

  private

  def destroy_background_batch
    @background_batch.destroy
    head :no_content
  end

  def load_background_batches
    @background_batches = background_batch_scope.reorder(sorting_param)
                                                .page(page_number_param)
                                                .per(per_page_param)
  end

  def load_background_batch
    @background_batch ||= BackgroundBatch.find_by!(id: params[:id])
  end

  def render_background_batch
    render json: @background_batch,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_background_batch
    build_background_batch
    authorize_background_batch

    if save_background_batch
      render_background_batch
    else
      render_with_resource_errors(@background_batch)
    end
  end

  def build_background_batch
    @background_batch ||= background_batch_scope.build
    @background_batch.assign_attributes(background_batch_params)
  end

  def save_background_batch
    @background_batch.save(context: persistence_context)
  end

  def background_batch_params
    params
      .require(:background_batch)
      .permit(BackgroundBatch::PERMITTED_ATTRIBUTES)
  end

  def background_batch_scope
    current_user.background_batches
  end

  def authorize_background_batch
    authorize @background_batch
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
