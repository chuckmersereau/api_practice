require 'csv'

class Api::V2::Contacts::ExportsController < Api::V2Controller
  supports_accept_header_content_types :any
  supports_content_types :any

  include ActionController::MimeResponds
  include ActionController::Helpers
  include ContactsHelper
  helper ContactsHelper

  def index
    load_contacts
    render_export
  end

  private

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
      Contact::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym)
  end

  def file_timestamp
    Time.now.strftime('%Y%m%d')
  end

  def render_export
    respond_to do |format|
      format.csv do
        render_csv("contacts-#{file_timestamp}.csv")
      end

      format.xlsx do
        render_xlsx("contacts-#{file_timestamp}.xlsx")
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
end
