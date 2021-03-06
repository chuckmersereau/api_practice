class PhoneNumber < ApplicationRecord
  include Concerns::AfterValidationSetSourceToMPDX
  include HasPrimary
  @@primary_scope = :person

  audited associated_with: :person, except: [:updated_at, :global_registry_id]

  LOCATIONS = [_('Mobile'), _('Home'), _('Work')].freeze

  PERMITTED_ATTRIBUTES = [:created_at,
                          :country_code,
                          :location,
                          :number,
                          :overwrite,
                          :primary,
                          :remote_id,
                          :source,
                          :updated_at,
                          :updated_in_db_at,
                          :id,
                          :valid_values].freeze

  belongs_to :person, touch: true

  before_save :clean_up_number
  before_create :set_valid_values

  validates :number, presence: true
  validates :number, :country_code, :location, :remote_id, updatable_only_when_source_is_mpdx: true

  global_registry_bindings parent: :person,
                           fields: { number: :string, primary: :boolean, location: :string }

  def self.add_for_person(person, attributes)
    attributes = attributes.with_indifferent_access.except(:_destroy)
    normalized_number = PhoneNumber.new(attributes.merge(person: person))
    normalized_number.clean_up_number
    normalized_or_not = [normalized_number.number, attributes[:number]]

    number = person.phone_numbers.find_by(number: normalized_or_not)
    if number && (attributes[:source] != TntImport::SOURCE || number.source == attributes[:source])
      number.update_attributes(attributes)
    else
      attributes['primary'] = person.phone_numbers.empty? if attributes['primary'].nil?
      new_or_create = person.new_record? ? :new : :create
      number = person.phone_numbers.send(new_or_create, attributes)
    end
    number
  end

  def clean_up_number
    # Default country to United States to help prevent duplicate numbers from
    # being created when the user has not selected a home country.
    country = user_country || 'US'

    # Use PhoneLib for parsing because PhoneLib supports extensions
    phone = Phonelib.parse(number, country)
    return if phone.e164.blank?
    self.number = phone.extension.present? ? "#{phone.e164};#{phone.extension}" : phone.e164
    self.country_code = phone.country_code
  end

  def ==(other)
    return false unless other.is_a?(PhoneNumber)
    number.to_s.gsub(/\D/, '') == other.number.to_s.gsub(/\D/, '')
  end

  def merge(other)
    self.primary = (primary? || other.primary?)
    self.country_code = other.country_code if country_code.blank?
    self.location = other.location if location.blank?
    self.remote_id = other.remote_id if remote_id.blank?
    save(validate: false)
    other.destroy
  end

  def user_country
    return @user_country if @user_country
    return nil unless person&.contacts&.first && person.contacts.first.account_list &&
                      person.contacts.first.account_list.home_country
    code = Address.find_country_iso(person.contacts.first.account_list.home_country)
    return nil unless code
    @user_country = code.downcase.to_sym
  end

  def set_valid_values
    self.valid_values = (source == MANUAL_SOURCE) || !self.class.where(person: person).exists?
    true
  end
end
