class Api::V2::User::OptionsController < Api::V2Controller
  resource_type :user_options

  def index
    load_options
    render json: @options.preload_valid_associations(include_associations),
           meta: meta_hash(@options),
           include: include_params,
           fields: field_params
  end

  def show
    load_option
    authorize_option
    render_option
  end

  def create
    persist_option
  end

  def update
    load_option
    authorize_option
    persist_option
  end

  def destroy
    load_option
    authorize_option
    destroy_option
  end

  private

  def option_params
    params
      .require(:user_option)
      .permit(option_attributes)
  end

  def option_attributes
    ::User::Option::PERMITTED_ATTRIBUTES
  end

  def option_scope
    current_user.options
  end

  def authorize_option
    authorize @option
  end

  def build_option
    @option ||= option_scope.build
    @option.assign_attributes(option_params)
  end

  def destroy_option
    @option.destroy
    head :no_content
  end

  def load_option
    @option ||= option_scope.find_by!(key: params[:id])
  end

  def load_options
    @options = option_scope
               .where(filter_params)
               .reorder(sorting_param)
               .page(page_number_param)
               .per(per_page_param)
  end

  def persist_option
    build_option
    authorize_option

    if save_option
      render_option
    else
      render_with_resource_errors(@option)
    end
  end

  def render_option
    render json: @option,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_option
    @option.save(context: persistence_context)
  end
end
