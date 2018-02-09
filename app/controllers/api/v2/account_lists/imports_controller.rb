class Api::V2::AccountLists::ImportsController < Api::V2Controller
  def show
    load_import
    authorize_import
    render_import
  end

  private

  def load_import
    @import ||= Import.find_by!(id: params[:id])
  end

  def render_import
    render json: @import,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def authorize_import
    authorize @import
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(id: params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
