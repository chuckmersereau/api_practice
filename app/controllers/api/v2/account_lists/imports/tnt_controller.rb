# This controller supports Content-Type multipart/form-data for file uploads. An example request in curl could look like:
#
#   curl "http://localhost:3000/api/v2/account_lists/23882dc0-e7d2-4170-8667-f1896e8427fa/imports/tnt" \
#        -X POST                                                                                       \
#        -H "Authorization: ..."                                                                       \
#        -H 'Content-Type: multipart/form-data'                                                        \
#        -F 'data[attributes][file]=@/Users/sheldon/Dev/mpdx_api/spec/fixtures/tnt/tnt_export.xml'     \
#        -F 'data[attributes][source]=tnt'

class Api::V2::AccountLists::Imports::TntController < Api::V2Controller
  resource_type :imports
  supports_content_types 'multipart/form-data'

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
    params.require(:data).require(:attributes).permit(Import::PERMITTED_ATTRIBUTES)
  end

  def import_scope
    load_account_list.imports
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(uuid: params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
