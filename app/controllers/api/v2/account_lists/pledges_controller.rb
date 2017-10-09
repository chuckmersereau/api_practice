class Api::V2::AccountLists::PledgesController < Api::V2Controller
  def index
    authorize_pledges
    load_pledges

    render json: @pledges.preload_valid_associations(include_associations),
           meta: meta_hash(@pledges),
           include: include_params,
           fields: field_params
  end

  def show
    load_pledge
    authorize_pledge

    render_pledge
  end

  def create
    persist_pledge
  end

  def update
    load_pledge
    authorize_pledge

    persist_pledge
  end

  def destroy
    load_pledge
    authorize_pledge
    destroy_pledge
  end

  private

  def pledge_params
    params
      .require(:pledge)
      .permit(pledge_attributes)
  end

  def pledge_attributes
    Pledge::PERMITTED_ATTRIBUTES
  end

  def pledge_scope
    load_account_list.pledges
  end

  def authorize_pledge
    authorize @pledge
  end

  def authorize_pledges
    authorize load_account_list, :show?
  end

  def build_pledge
    @pledge ||= pledge_scope.build
    @pledge.assign_attributes(pledge_params)
  end

  def destroy_pledge
    @pledge.destroy
    head :no_content
  end

  def load_pledge
    @pledge ||= Pledge.find_by!(uuid: params[:id])
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(uuid: params[:account_list_id])
  end

  def load_pledges
    @pledges = pledge_scope.where(filter_params)
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def permitted_filters
    [:contact_id, :appeal_id, :status]
  end

  def persist_pledge
    build_pledge
    authorize_pledge

    if save_pledge
      render_pledge
    else
      render_with_resource_errors(@pledge)
    end
  end

  def permitted_sorting_params
    %w(amount expected_date)
  end

  def render_pledge
    render json: @pledge,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_pledge
    @pledge.save(context: persistence_context)
  end
end
