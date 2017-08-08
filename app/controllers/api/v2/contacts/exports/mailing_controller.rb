require 'csv'

class Api::V2::Contacts::Exports::MailingController < Api::V2Controller
  supports_accept_header_content_types :any
  supports_content_types :any

  include ActionController::MimeResponds

  def index
    load_contacts
    log_export
    render_export
  end

  private

  def log_export
    ExportLog.create(
      type: 'Contacts Mailing',
      params: params,
      user: current_user,
      export_at: DateTime.now
    )
  end

  def load_contacts
    @contacts ||= filter_contacts.order(name: :asc).preload(:primary_person, :spouse, :primary_address,
                                                            :tags, people: [:email_addresses, :phone_numbers])
  end

  def filter_contacts
    @filtered_contacts = Contact::Filterer.new(filter_params)
                                          .filter(scope: contact_scope, account_lists: account_lists)
    @filtered_contacts
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

  def filename
    @filename ||= "contacts-#{Time.now.strftime('%Y%m%d')}.csv"
  end

  def render_export
    respond_to do |format|
      format.csv do
        headers['Content-Type'] ||= 'text/csv'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        render text: CsvExport.mailing_addresses(@contacts), filename: filename
      end
    end
  end
end
