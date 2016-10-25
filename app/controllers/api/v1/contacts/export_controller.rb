class Api::V1::Contacts::ExportController < Api::V1::BaseController
  before_action :load_contacts

  def primary
    load_contacts
    @contacts = @contacts.includes(:primary_person, :spouse, :primary_address, :tags,
                                   people: [:email_addresses, :phone_numbers])
    @csv_primary_emails_only ||= params[:csv_primary_emails_only]

    respond_to do |format|
      format.csv do
        render_csv("contacts-#{Time.now.strftime('%Y%m%d')}")
      end

      format.xlsx do
        render xlsx: 'index', filename: "contacts-#{Time.now.strftime('%Y%m%d')}.xlsx"
      end
    end
  end

  def mailing
    load_contacts
    @contacts = @contacts.includes(:primary_person, :spouse, :primary_address)

    @fields_mapping = {
      'Contact Name' => :name,
      'Greeting' => :greeting,
      'Envelope Greeting' => :envelope_greeting,
      'Mailing Street Address' => [:mailing_address, :csv_street],
      'Mailing City' => [:mailing_address, :city],
      'Mailing State' => [:mailing_address, :state],
      'Mailing Postal Code' => [:mailing_address, :postal_code],
      'Mailing Country' => :csv_country,
      'Address Block' => :address_block
    }
    @rows = @contacts.map do |contact|
      @fields_mapping.values.map { |method| value_for_contact_field(contact, method) }
    end

    respond_to do |format|
      format.csv { render_csv("contacts-mailing-#{Time.now.strftime('%Y%m%d')}") }
    end
  end

  protected

  def load_contacts
    @contacts ||= Contact::Filterer.new(params[:filters]).filter(contact_scope, current_account_list)
  end

  def contact_scope
    current_account_list.contacts
  end

  private

  def value_for_contact_field(contact, method)
    @contacts_account_list ||= contact.account_list
    return contact.mailing_address.csv_country(@contacts_account_list.home_country) if method == :csv_country
    if method == :address_block
      return "#{contact.envelope_greeting}\n#{contact.mailing_address.to_snail.gsub("\r\n", "\n")}"
    end
    return contact.try(method) unless method.is_a?(Array)
    holder = contact
    method.each { |m| holder = holder.try(m) }
    holder
  end
end
