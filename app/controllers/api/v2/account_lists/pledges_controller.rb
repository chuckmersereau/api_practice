class Api::V2::AccountLists::PledgesController < Api::V2Controller
  def index
    authorize_pledges
    load_pledges

    render_pledges
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

  protected

  def permit_coach?
    %w(index show).include? params[:action]
  end

  private

  def coach?
    !load_account_list.users.where(id: current_user).exists? &&
      load_account_list.coaches.where(id: current_user).exists?
  end

  def pledge_params
    params
      .require(:pledge)
      .permit(pledge_attributes)
  end

  def pledge_attributes
    Pledge::PERMITTED_ATTRIBUTES
  end

  def pledge_scope
    scope = load_account_list.pledges
    if coach?
      scope = scope.where('expected_date < ?', Date.today)
                   .where(appeal_id: load_account_list.primary_appeal_id, status: :not_received)
    end
    scope
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
    @pledge ||= Pledge.find(params[:id])
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def load_pledges
    @pledges = filter_pledges.joins(sorting_join)
                             .reorder(sorting_param)
                             .page(page_number_param)
                             .per(per_page_param)
  end

  def filter_pledges
    filters = if coach?
                # only allow coach to filter by contact_id
                filter_params.slice(:contact_id)
              else
                filter_params
              end
    pledge_scope.where(filters)
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
    %w(amount expected_date contact.name)
  end

  def render_pledges
    options = base_render_options.merge(json: @pledges.preload_valid_associations(include_associations),
                                        meta: meta_hash(@pledges))
    options[:each_serializer] = Coaching::PledgeSerializer if coach?
    render options
  end

  def render_pledge
    options = base_render_options.merge(json: @pledge, status: success_status)
    options[:serializer] = Coaching::PledgeSerializer if coach?
    render options
  end

  def base_render_options
    {
      include: include_params,
      fields: field_params
    }
  end

  def save_pledge
    @pledge.save(context: persistence_context)
  end
end
