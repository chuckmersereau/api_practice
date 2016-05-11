class PhoneNumber < ActiveRecord::Base
  include HasPrimary
  @@primary_scope = :person

  has_paper_trail on: [:destroy], ignore: [:updated_at],
                  meta: { related_object_type: 'Person',
                          related_object_id: :person_id }

  LOCATIONS = [_('Mobile'), _('Home'), _('Work')].freeze

  belongs_to :person, touch: true

  before_save :clean_up_number

  validates :number, presence: true

  # attr_accessible :number, :primary, :country_code, :location, :remote_id

  def self.add_for_person(person, attributes)
    attributes = attributes.with_indifferent_access.except(:_destroy)
    normalized_number = PhoneNumber.new(attributes.merge(person: person))
    normalized_number.clean_up_number
    normalized_or_not = [normalized_number.number, attributes[:number]]

    if number = person.phone_numbers.find_by(number: normalized_or_not)
      number.update_attributes(attributes)
    else
      attributes['primary'] = (person.phone_numbers.present? ? false : true) if attributes['primary'].nil?
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
    return false if phone.e164.blank?
    self.number = phone.extension.present? ? "#{phone.e164};#{phone.extension}" : phone.e164
    self.country_code = phone.country_code
    true
  end

  def ==(other)
    return false unless other.is_a?(PhoneNumber)
    number.gsub(/\D/, '') == other.number.gsub(/\D/, '')
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
    return nil unless person && person.contacts.first && person.contacts.first.account_list &&
                      person.contacts.first.account_list.home_country
    code = Address.find_country_iso(person.contacts.first.account_list.home_country)
    return nil unless code
    @user_country = code.downcase.to_sym
  end
end
