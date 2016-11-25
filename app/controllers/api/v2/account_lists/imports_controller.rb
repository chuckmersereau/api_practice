class Api::V2::AccountLists::ImportsController < Api::V2Controller
  def show
    load_import
    authorize_import
    render_import
  end

  def create
    persist_import
  end

  private

  def load_import
    @import ||= Import.find(params[:id])
  end

  def render_import
    render json: @import
  end

  def persist_import
    build_import
    authorize_import
    return show if save_import
    render_400_with_errors(@import)
  end

  def build_import
    @import ||= import_scope.build
    @import.assign_attributes(import_params)
  end

  def authorize_import
    authorize @import
  end

  def save_import
    @import.save
  end

  def import_params
    params.require(:data).require(:attributes).permit(Import::PERMITTED_ATTRIBUTES)
  end

  def import_scope
    load_account_list.imports
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, load_account_list)
  end
end
