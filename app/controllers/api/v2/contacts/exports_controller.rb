require 'csv'

class Api::V2::Contacts::ExportsController < Api::V2Controller
  supports_accept_header_content_types :any
  supports_content_types :any
  resource_type 'export_logs'

  include ActionController::MimeResponds
  include ActionController::Helpers
  include ContactsHelper
  helper ContactsHelper

  def index
    persist_export
    deactivate_export
  end

  def show
    load_export
    authorize_export
    deactivate_export
    render_export
  end

  def create
    persist_export
  end

  protected

  def load_export
    @export ||= ExportLog.find(params[:id])
  end

  def deactivate_export
    @export.update(active: false)
  end

  def authorize_export
    authorize @export, :show?
  end

  def build_export
    @export = ExportLog.new
    @export.attributes = export_params
  end

  def save_export
    @export.save
  end

  def persist_export
    build_export
    authorize_export

    if save_export
      render_export
    else
      render_with_resource_errors(@export)
    end
  end

  def export_params
    {
      type: export_log_type,
      params: (params.dig(:export_log, :params) || params).to_json,
      user: current_user,
      export_at: DateTime.now
    }
  end

  def export_log_type
    'Contacts'
  end

  def render_export
    request.format = :json unless params[:format]

    respond_to do |format|
      format.csv do
        load_contacts
        render_csv("contacts-#{file_timestamp}.csv")
      end

      format.xlsx do
        load_contacts
        render_xlsx("contacts-#{file_timestamp}.xlsx")
      end

      format.json do
        render json: @export,
               status: success_status,
               include: include_params,
               fields: field_params
      end
    end
  end

  def render_csv(filename)
    headers['Content-Type'] ||= 'text/csv'
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render csv: 'index', filename: filename
  end

  def render_xlsx(filename)
    render xlsx: 'index', filename: filename
  end

  def load_contacts
    @contacts ||= filter_contacts.order(name: :asc).preload(:primary_person, :spouse, :primary_address,
                                                            :tags, people: [:email_addresses, :phone_numbers])
  end

  def filter_contacts
    Contact::Filterer.new(filter_params).filter(scope: contact_scope, account_lists: account_lists)
  end

  def account_list_filter
    JSON.parse(@export.params).dig('filter', 'account_list_id')
  end

  def contact_scope
    current_user.contacts.where(account_list: account_lists)
  end

  def permitted_filters
    @permitted_filters ||=
      Contact::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym) +
      Contact::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym) +
      [:account_list_id, :any_tags]
  end

  def file_timestamp
    Time.now.strftime('%Y%m%d')
  end

  def filter_params
    super(JSON.parse(@export.params).dig('filter'))
  end
end
