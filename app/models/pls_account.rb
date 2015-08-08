require 'async'
require 'open-uri'

class PlsAccount < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true
  SERVICE_URL = 'https://www.myletterservice.org'

  belongs_to :account_list
  after_create :queue_subscribe_contacts
  validates :oauth2_token, :account_list_id,  presence: true

  def queue_subscribe_contacts
    async(:subscribe_contacts)
  end

  def subscribe_contacts
    contacts = account_list.contacts.includes([:primary_address, { primary_person: :companies }])
               .select(&:should_be_in_prayer_letters?)
    contacts.each(&method(:add_or_update_contact))

    # Using PLS api put method below is buggy, so for now we can't use it.
    #
    # contact_subscribe_params = contacts.map { |c| contact_params(c, true) }
    # contact_params_map = Hash[contacts.map { |c| [c.id, contact_params(c)] }]
    #
    # # Delete the existing contacts first
    # contacts.select { |c| c.pls_id.present? }.each(&method(:delete_contact))
    #
    # get_response(:put, '/api/v1/contacts', { contacts: contact_subscribe_params }.to_json, 'application/json')
    # account_list.contacts.update_all(pls_id: nil, pls_params: nil)
    # import_list(contact_params_map)
  end

  def import_list(contact_params_map = nil)
    contacts = JSON.parse(get_response(:get, '/api/v1/contacts'))['contacts']

    contacts.each do |pl_contact|
      next unless pl_contact['external_id'] &&
                  contact = account_list.contacts.find_by(id: pl_contact['external_id'])

      contact.update_columns(pls_id: pl_contact['contact_id'],
                             pls_params: contact_params_map ? contact_params_map[contact.id] : nil)
    end
  end

  def active?
    valid_token?
  end

  def contacts(params = {})
    JSON.parse(get_response(:get, '/api/v1/contacts?' + params.map { |k, v| "#{k}=#{v}" }.join('&')))['contacts']
  end

  def add_or_update_contact(contact)
    async(:async_add_or_update_contact, contact.id)
  end

  def async_add_or_update_contact(contact_id)
    contact = account_list.contacts.find(contact_id)
    if contact.pls_id.present?
      update_contact(contact)
    else
      create_contact(contact)
    end
  end

  def create_contact(contact)
    contact_params = contact_params(contact)
    json = JSON.parse(get_response(:post, '/api/v1/contacts', contact_params))
    contact.update_columns(pls_id: json['contact_id'], pls_params: contact_params)
  rescue AccessError
    # do nothing
  rescue RestClient::BadRequest => e
    # BadRequest: A contact must have a name or company. Monitor those cases for pattern / underlying causes.
    Airbrake.raise_or_notify(e, parameters: contact_params)
  end

  def contact_needs_sync?(contact)
    contact_params(contact) != contact.pls_params
  end

  def update_contact(contact)
    params = contact_params(contact)
    return if params == contact.pls_params
    get_response(:post, '/api/v1/contacts', params)
    contact.update_column(:pls_params, params)
  rescue AccessError
    # do nothing
  rescue RestClient::Gone, RestClient::ResourceNotFound
    handle_missing_contact(contact)
  end

  def handle_missing_contact(contact)
    contact.update_columns(pls_id: nil, pls_params: nil)
    queue_subscribe_contacts
  end

  def delete_contact(contact)
    get_response(:delete, "/api/v1/contacts/#{contact.pls_id}")
    contact.update_columns(pls_id: nil, pls_params: nil)
  rescue RestClient::InternalServerError
    # Do nothing as this means the contact was already deleted
  end

  def delete_all_contacts
    get_response(:delete, '/api/v1/contacts')
    account_list.contacts.update_all(pls_id: nil, pls_params: nil)
  end

  def contact_params(contact, subscribe_format = false)
    name = contact.siebel_organization? ? '' : contact.envelope_greeting
    params = { name: name, greeting: contact.greeting, file_as: contact.name,
               external_id: contact.id,
               company: contact.siebel_organization? ? contact.name : '',
               envLine: name }

    address = contact.mailing_address
    address_params = { street: address.street, city: address.city, state: address.state,
                       postCode: address.postal_code,
                       country: address.country == 'United States' ? '' : address.country.to_s }
    address_params[:country] = address.country unless address.country == 'United States'
    if subscribe_format
      params[:contact_id] = contact.pls_id
      params[:address] = address_params
    else
      params.merge!(address_params)
    end

    params
  end

  def get_response(method, path, params = nil, content_type = nil)
    return unless active?

    headers = { 'Authorization' => "Bearer #{URI.encode(oauth2_token)}" }
    headers['Content-Type'] = content_type if content_type
    RestClient::Request.execute(method: method, url: SERVICE_URL + path, payload: params, headers: headers)
  rescue RestClient::ServiceUnavailable
    # Do nothing, as the PLS api mistakenly returns this error
  rescue RestClient::Unauthorized, RestClient::Forbidden
    handle_bad_token
  end

  def handle_bad_token
    update_column(:valid_token, false)
    AccountMailer.pls_invalid_token(account_list).deliver

    fail AccessError
  end

  class AccessError < StandardError
  end
end
