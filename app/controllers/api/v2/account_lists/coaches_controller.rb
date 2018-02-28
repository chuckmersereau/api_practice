class Api::V2::AccountLists::CoachesController < Api::V2Controller
  resource_type :users

  def index
    authorize load_account_list, :show?
    load_coaches
    render json: @coaches.preload_valid_associations(include_associations),
           meta: meta_hash(@coaches),
           include: include_params,
           fields: field_params,
           each_serializer: AccountListUserSerializer
  end

  def show
    load_coach
    authorize_coach
    render_coach
  end

  def destroy
    load_coach
    authorize_coach
    destroy_coach
  end

  private

  def destroy_coach
    @coach.remove_coach_access(load_account_list)
    head :no_content
  end

  def load_coaches
    @coaches = coach_scope.where(filter_params)
                          .reorder(sorting_param)
                          .order(:created_at)
                          .page(page_number_param)
                          .per(per_page_param)
  end

  def load_coach
    @coach ||= User::Coach.find(params[:id])
  end

  def render_coach
    render json: @coach,
           status: success_status,
           include: include_params,
           fields: field_params,
           serializer: AccountListUserSerializer
  end

  def authorize_coach
    authorize @coach
  end

  def coach_scope
    load_account_list.coaches
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def pundit_user
    if action_name == 'index'
      PunditContext.new(current_user, account_list: load_account_list)
    else
      current_user
    end
  end
end
