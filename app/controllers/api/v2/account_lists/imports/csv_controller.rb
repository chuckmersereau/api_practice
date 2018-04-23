# This controller supports Content-Type multipart/form-data for file uploads. An example request in curl could look like:
#
#   curl "http://localhost:3000/api/v2/account_lists/23882dc0-e7d2-4170-8667-f1896e8427fa/imports/csv"   \
#        -X POST                                                                                         \
#        -H "Authorization: ..."                                                                         \
#        -H 'Content-Type: multipart/form-data'                                                          \
#        -F 'data[attributes][file]=@/Users/sheldon/Dev/mpdx_api/spec/fixtures/sample_csv_to_import.csv' \
#        -F "data[type]=imports"

class Api::V2::AccountLists::Imports::CsvController < Api::V2Controller
  resource_type :imports
  supports_content_types 'multipart/form-data', 'application/vnd.api+json'

  def index
    authorize_imports
    load_imports
    render_imports
  end

  def show
    load_import
    authorize_import
    render_import
  end

  def create
    persist_import
  end

  def update
    load_import
    authorize_import
    persist_import
  end

  private

  def load_import
    @import ||= import_scope.find(params[:id])
  end

  def load_imports
    @imports = import_scope.reorder(sorting_param)
                           .order(default_sort_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def render_import
    render json: @import,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def render_imports
    render json: @imports.preload_valid_associations(include_associations),
           meta: meta_hash(@imports),
           include: include_params,
           fields: field_params
  end

  def persist_import
    build_import
    authorize_import
    if save_import
      CsvImport.new(@import).update_cached_file_data
      render_import
    else
      render_with_resource_errors(@import)
    end
  end

  def build_import
    @import ||= import_scope.build(in_preview: true)
    @import.assign_attributes(import_params)
  end

  def authorize_import
    authorize @import
  end

  def authorize_imports
    authorize load_account_list, :show?
  end

  def save_import
    @import.save(context: persistence_context)
  end

  def import_params
    params
      .require(:import)
      .permit(Import::PERMITTED_ATTRIBUTES)
      .merge(source: 'csv', user_id: current_user.id)
      .tap do |permit_params| # Permit all parameters underneath the mappings params
        permit_params[:file_constants_mappings] = params[:import][:file_constants_mappings] unless params.dig(:import, :file_constants_mappings).nil?
        permit_params[:file_headers_mappings] = params[:import][:file_headers_mappings] unless params.dig(:import, :file_headers_mappings).nil?
      end
  end

  def import_scope
    load_account_list.imports.where(source: 'csv')
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def default_sort_param
    Import.arel_table[:created_at].asc
  end
end
