require 'smarty_streets'

class Address < ApplicationRecord
  has_paper_trail on: [:create, :update, :destroy],
                  if: proc { |address| address.record_paper_trail? },
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

  alias destroy! destroy

  attr_accessor :user_changed

  # Indicates an address was manually created/updated. Otherwise source is usually the import class name.
  MANUAL_SOURCE = 'manual'.freeze

  PERMITTED_ATTRIBUTES = [:city,
                          :created_at,
                          :country,
                          :end_date,
                          :location,
                          :metro_area,
                          :postal_code,
                          :primary_mailing_address,
                          :region,
                          :remote_id,
                          :seasonal,
                          :start_date,
                          :state,
                          :street,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  assignable_values_for :location, allow_blank: true do
    [_('Home'), _('Business'), _('Mailing'), _('Seasonal'), _('Other'), _('Temporary')]
  end

  def record_paper_trail?
    # This has the effect of logging all deletes, all creates and the updates
    # associated with a "log_debug_info" account list.
    changes['deleted'].present? || marked_for_destruction? ||
      changes['id'].present? ||
      (addressable.is_a?(Contact) && addressable&.account_list&.log_debug_info)
  end

  def equal_to?(other)
    return false unless other
    other.master_address_id && master_address_id == other.master_address_id ||
      (address_fields_equal?(other) && country_equal?(other) &&
       postal_code_equals?(other))
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

    country = countries.find { |c| c[:name].casecmp(val.downcase).zero? }
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

  def self.find_country_iso(val)
    return nil if val.nil? || val.empty?
    val = val.upcase
    Snail.lookup_country_iso(val) ||
      Snail::Iso3166::ALPHA2.select { |_key, array| array.include? val }.keys.first ||
      Snail::Iso3166::ALPHA2.select { |_key, array| array.include? val }.keys.first ||
      Snail::Iso3166::ALPHA2_EXCEPTIONS.select { |_key, array| array.include? val }.keys.first
  end

  def fix_encoding_if_equal(other)
    return unless equal_to?(other)
    [:street, :city, :state, :country, :postal_code].each do |field|
      next unless send(field) == old_encoding(other.send(field))
      self[field] = other.send(field)
    end
    save
  end

  def postal_code_prefix
    no_whitespace(postal_code).downcase[0..4]
  end

  private

  def postal_code_equals?(other)
    postal_code_prefix == other.postal_code_prefix ||
      equals_old_encoding?(postal_code, other.postal_code)
  end

  def address_fields_equal?(other)
    [:street, :city, :state].all? do |field|
      equals_old_encoding?(send(field), other.send(field))
    end
  end

  def country_equal?(other)
    country.blank? || other.country.blank? || equals_old_encoding?(country, other.country)
  end

  def equals_old_encoding?(s1, s2)
    s1.blank? && s2.blank? || no_whitespace(s1).casecmp(no_whitespace(s2)).zero? ||
      old_encoding(s1) == s2 || s1 == old_encoding(s2)
  end

  def no_whitespace(str)
    str.to_s.gsub(/\s+/, '')
  end

  def old_encoding(str)
    return unless str
    # This encoding trick was used for a time in DataServer. It would mangle
    # special characters and was eventually replaced. That means that some
    # addresses be duplicated (having old and new encoding versions) if they
    # contained special characters.
    str.unpack('C*').pack('U*')
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
       (attributes_for_master_address[:country].to_s.casecmp('united states').zero? ||
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
  ].freeze
end
