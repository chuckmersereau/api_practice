require 'smarty_streets'

class Address < ActiveRecord::Base
  has_paper_trail on: [:destroy, :update],
                  meta: { related_object_type: :addressable_type,
                          related_object_id: :addressable_id },
                  ignore: [:updated_at]

  belongs_to :addressable, polymorphic: true, touch: true
  belongs_to :master_address
  belongs_to :source_donor_account, class_name: 'DonorAccount'

  scope :current, -> { where(deleted: false) }

  before_validation :determine_master_address
  before_save :set_manual_source_if_user_changed
  after_destroy :clean_up_master_address
  after_save :update_contact_timezone

  alias_method :destroy!, :destroy

  attr_accessor :user_changed

  # Indicates an address was manually created/updated. Otherwise source is usually the import class name.
  MANUAL_SOURCE = 'manual'

  assignable_values_for :location, allow_blank: true do
    [_('Home'), _('Business'), _('Mailing'), _('Seasonal'), _('Other'), _('Temporary')]
  end

  def equal_to?(other)
    if other
      return true if other.master_address_id && other.master_address_id == master_address_id

      return true if other.street.to_s.downcase == street.to_s.downcase &&
                     other.city.to_s.downcase == city.to_s.downcase &&
                     other.state.to_s.downcase == state.to_s.downcase &&
                     (other.country.to_s.downcase == country.to_s.downcase || country.blank? || other.country.blank?) &&
                     other.postal_code.to_s[0..4].downcase == postal_code.to_s[0..4].downcase
    end

    false
  end

  def destroy
    update_attributes(deleted: true, primary_mailing_address: false)
  end

  def not_blank?
    attributes.with_indifferent_access.slice(:street, :city, :state, :country, :postal_code).any? { |_, v| v.present? && v.strip != '(UNDELIVERABLE)' }
  end

  def merge(other_address)
    self.primary_mailing_address = (primary_mailing_address? || other_address.primary_mailing_address?)
    self.seasonal = (seasonal? || other_address.seasonal?)
    self.location = other_address.location if location.blank?
    self.remote_id = other_address.remote_id if remote_id.blank?
    self.source_donor_account = other_address.source_donor_account if source_donor_account.blank?
    self.start_date = [start_date, other_address.start_date].compact.min
    self.source = remote_id.present? ? 'Siebel' : [source, other_address.source].compact.first
    save(validate: false)
    other_address.destroy!
  end

  def country=(val)
    self[:country] = self.class.normalize_country(val)
  end

  def self.normalize_country(val)
    return if val.blank?
    val = val.strip

    countries = CountrySelect::COUNTRIES

    country = countries.find { |c| c[:name].downcase == val.downcase }
    return country[:name] if country

    countries.each do |c|
      next unless c[:alternatives].downcase.include?(val.downcase)
      return c[:name]
    end

    # If we couldn't find a match anywhere, go ahead and return the country
    val
  end

  def valid_mailing_address?
    city.present? && street.present?
  end

  def geo
    return unless master_address
    master_address.geo
  end

  # Not private because Google Contacts sync uses it to normalize addresses without needing to create a record
  def find_or_create_master_address
    unless master_address_id
      master_address = find_master_address

      unless master_address
        master_address = MasterAddress.create(attributes_for_master_address)
      end

      self.master_address_id = master_address.id
      self.verified = master_address.verified
    end

    true
  end

  def csv_street
    street.gsub("\r\n", "\n").strip if street
  end

  def csv_country(home_country)
    if country == home_country
      ''
    else
      country
    end
  end

  def to_snail
    origin = addressable.try(:account_list) ? Address.find_country_iso(addressable.account_list.home_country) : 'US'
    Snail.new(
      line_1: street, postal_code: postal_code, city: city,
      region: state, country: Address.find_country_iso(country),
      origin: origin
    ).to_s
  end

  private

  def self.find_country_iso(val)
    return nil if val.nil? || val.empty?
    val = val.upcase
    Snail.lookup_country_iso(val) ||
      Snail::Iso3166::ALPHA2.select { |_key, array| array.include? val }.keys.first ||
      Snail::Iso3166::ALPHA2.select { |_key, array| array.include? val }.keys.first ||
      Snail::Iso3166::ALPHA2_EXCEPTIONS.select { |_key, array| array.include? val }.keys.first
  end

  def set_manual_source_if_user_changed
    return unless user_changed && (new_record? || place_fields_changed?)
    self.source = MANUAL_SOURCE
    self.start_date = Date.today
    self.source_donor_account = nil
  end

  def place_fields_changed?
    place_fields = %w(street city state postal_code)
    place_fields.any? { |f| changes[f].present? && changes[f][0].to_s.strip != changes[f][1].to_s.strip } ||
      (changes['country'].present? &&
        self.class.normalize_country(changes['country'][0]) != self.class.normalize_country(changes['country'][1]))
  end

  def determine_master_address
    if id.blank?
      find_or_create_master_address
    else
      update_or_create_master_address
    end
  end

  def update_or_create_master_address
    if place_fields_changed?
      new_master_address_match = find_master_address

      if master_address.nil? || master_address != new_master_address_match
        unless new_master_address_match
          new_master_address_match = MasterAddress.create(attributes_for_master_address)
        end

        self.master_address_id = new_master_address_match.id
        self.verified = new_master_address_match.verified
      end
    end

    true
  end

  def clean_up_master_address
    master_address.destroy if master_address && master_address.addresses.where.not(id: id).empty?

    true
  end

  def find_master_address
    master_address = MasterAddress.find_by(attributes_for_master_address.slice(:street, :city, :state, :country, :postal_code))

    # See if another address in the database matches this one and has a master address
    where_clause = attributes_for_master_address.symbolize_keys
                   .slice(:street, :city, :state, :country, :postal_code)
                   .map { |k, _v| "lower(#{k}) = :#{k}" }.join(' AND ')

    master_address ||= Address.where(where_clause, attributes_for_master_address)
                       .find_by('master_address_id is not null')
                       .try(:master_address)

    if !master_address &&
       (attributes_for_master_address[:state].to_s.length == 2 ||
        attributes_for_master_address[:postal_code].to_s.length == 5 ||
        attributes_for_master_address[:postal_code].to_s.length == 10) &&
       (attributes_for_master_address[:country].to_s.downcase == 'united states' ||
        (attributes_for_master_address[:country].blank? && US_STATES.flatten.map(&:upcase).include?(attributes_for_master_address[:state].to_s.upcase)))

      begin
        results = SmartyStreets.get(attributes_for_master_address)
        if results.length == 1
          ss_address = results.first['components']
          attributes_for_master_address[:street] = results.first['delivery_line_1'].downcase
          attributes_for_master_address[:city] = ss_address['city_name'].downcase
          attributes_for_master_address[:state] = ss_address['state_abbreviation'].downcase
          attributes_for_master_address[:postal_code] = [ss_address['zipcode'], ss_address['plus4_code']].compact.join('-').downcase
          attributes_for_master_address[:state] = ss_address['state_abbreviation'].downcase
          attributes_for_master_address[:country] = 'united states'
          attributes_for_master_address[:verified] = true
          master_address = MasterAddress.find_by(attributes_for_master_address.symbolize_keys
                                                                            .slice(:street, :city, :state, :country, :postal_code))
        end
        attributes_for_master_address[:smarty_response] = results
      rescue RestClient::RequestFailed, SocketError, RestClient::ResourceNotFound
        # Don't blow up if smarty didn't like the request
      end

      if results && results[0] && results[0]['metadata']
        meta = results[0]['metadata']
        attributes_for_master_address[:latitude] = meta['latitude'].to_s
        attributes_for_master_address[:longitude] = meta['longitude'].to_s
      end

      unless attributes_for_master_address[:latitude] && attributes_for_master_address[:longitude]
        begin
          lat, long = Geocoder.coordinates([attributes_for_master_address[:street],
                                            attributes_for_master_address[:city],
                                            attributes_for_master_address[:state],
                                            attributes_for_master_address[:country]].join(','))
          attributes_for_master_address[:latitude] = lat.to_s
          attributes_for_master_address[:longitude] = long.to_s
        rescue
          # Don't blow up if Google didn't like the request... Rate limit most likely.
        end
      end
    end

    master_address
  end

  def update_contact_timezone
    return unless primary_mailing_address?
    return unless (changed & %w(street city state country primary_mailing_address)).present?
    return unless addressable.respond_to?(:set_timezone)

    addressable.set_timezone
  end

  def attributes_for_master_address
    @attributes_for_master_address ||= Hash[attributes.symbolize_keys
                                            .slice(:street, :city, :state, :country, :postal_code)
                                            .select { |_k, v| v.present? }
                                            .map { |k, v| [k, v.downcase] }]
  end

  US_STATES =  [
    %w(Alabama AL),
    %w(Alaska AK),
    %w(Arizona AZ),
    %w(Arkansas AR),
    %w(California CA),
    %w(Colorado CO),
    %w(Connecticut CT),
    %w(Delaware DE),
    ['District of Columbia', 'DC'],
    %w(Florida FL),
    %w(Georgia GA),
    %w(Hawaii HI),
    %w(Idaho ID),
    %w(Illinois IL),
    %w(Indiana IN),
    %w(Iowa IA),
    %w(Kansas KS),
    %w(Kentucky KY),
    %w(Louisiana LA),
    %w(Maine ME),
    %w(Maryland MD),
    %w(Massachusetts MA),
    %w(Michigan MI),
    %w(Minnesota MN),
    %w(Mississippi MS),
    %w(Missouri MO),
    %w(Montana MT),
    %w(Nebraska NE),
    %w(Nevada NV),
    ['New Hampshire', 'NH'],
    ['New Jersey', 'NJ'],
    ['New Mexico', 'NM'],
    ['New York', 'NY'],
    ['North Carolina', 'NC'],
    ['North Dakota', 'ND'],
    %w(Ohio OH),
    %w(Oklahoma OK),
    %w(Oregon OR),
    %w(Pennsylvania PA),
    ['Puerto Rico', 'PR'],
    ['Rhode Island', 'RI'],
    ['South Carolina', 'SC'],
    ['South Dakota', 'SD'],
    %w(Tennessee TN),
    %w(Texas TX),
    %w(Utah UT),
    %w(Vermont VT),
    %w(Virginia VA),
    %w(Washington WA),
    ['West Virginia', 'WV'],
    %w(Wisconsin WI),
    %w(Wyoming WY)
  ]
end
