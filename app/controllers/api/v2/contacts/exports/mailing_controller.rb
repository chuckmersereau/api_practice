require 'csv'

class Api::V2::Contacts::Exports::MailingController < Api::V2Controller
  supports_accept_header_content_types :any
  supports_content_types :any

  include ActionController::MimeResponds
  include ActionController::Helpers
  include MailingExportsHelper
  helper MailingExportsHelper

  FIELDS_MAPPING = {
    'Contact Name' => :name,
    'Greeting' => :greeting,
    'Envelope Greeting' => :envelope_greeting,
    'Mailing Street Address' => :csv_street,
    'Mailing City' => :city,
    'Mailing State' => :state,
    'Mailing Postal Code' => :postal_code,
    'Mailing Country' => :csv_country,
    'Address Block' => :address_block
  }.freeze

  def index
    load_contacts
    load_rows
    render_export
  end

  private

  def load_contacts
    @contacts ||= filter_contacts.order(name: :asc).preload(:primary_person, :spouse, :primary_address,
                                                            :tags, people: [:email_addresses, :phone_numbers])
  end

  def load_rows
    @rows = @contacts.map do |contact|
      FIELDS_MAPPING.values.map { |method| ContactExhibit.new(contact, nil).send(method) }
    end
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
      [:account_list_id]
  end

  def file_timestamp
    Time.now.strftime('%Y%m%d')
  end

  def render_export
    respond_to do |format|
      format.csv do
        render_csv("contacts-#{file_timestamp}.csv")
      end
    end
  end

  def render_csv(filename)
    headers['Content-Type'] ||= 'text/csv'
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render csv: 'index', filename: filename
  end
end
