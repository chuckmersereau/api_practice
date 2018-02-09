class Api::V2::AccountLists::Imports::GoogleController < Api::V2Controller
  resource_type :imports

  def create
    persist_import
  end

  private

  def render_import
    render json: @import,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_import
    build_import
    authorize_import
    if save_import
      render_import
    else
      render_with_resource_errors(@import)
    end
  end

  def build_import
    @import ||= import_scope.build
    @import.assign_attributes(import_params)
  end

  def authorize_import
    authorize @import
  end

  def save_import
    @import.save(context: persistence_context)
  end

  def import_params
    params
      .require(:import)
      .permit(Import::PERMITTED_ATTRIBUTES)
      .merge(group_tags: params.require(:import).fetch(:group_tags, nil).try(:permit!))
      .merge(user_id: current_user.id)
  end

  def import_scope
    load_account_list.imports.where(source: 'google')
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(id: params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
