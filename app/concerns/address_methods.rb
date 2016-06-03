module AddressMethods
  extend ActiveSupport::Concern

  # Used by the copy_address below to know which attributes to exclude
  FIELDS_TO_NOT_COPY = [
    :id, :addressable_id, :created_at, :updated_at, :primary_mailing_address,
    :addressable_type, :remote_id, :source, :source_donor_account_id
  ].freeze

  included do
    has_many :addresses, (lambda do
      where(deleted: false)
        .order('addresses.primary_mailing_address::int desc')
        .order(:master_address_id).order(:street).order(:id)
    end), as: :addressable

    has_many :addresses_including_deleted, class_name: 'Address', as: :addressable

    has_one :primary_address, (lambda do
      where(primary_mailing_address: true, deleted: false).where.not(historic: true)
        .order(:master_address_id).order(:street).order(:id)
    end), class_name: 'Address', as: :addressable

    accepts_nested_attributes_for :addresses, reject_if: :blank_or_duplicate_address?, allow_destroy: true

    after_destroy :destroy_addresses
  end

  def blank_or_duplicate_address?(attributes)
    return false if attributes['id']

    place_attrs = attributes.symbolize_keys.slice(:street, :city, :state, :country, :postal_code)
    place_attrs[:country] = Address.normalize_country(place_attrs[:country])
    place_attrs.all? { |_, v| v.blank? } || !addresses.where(place_attrs).empty?
  end

  def address
    primary_address || addresses.first
  end

  def destroy_addresses
    addresses.map(&:destroy!)
  end

  def merge_addresses
    addresses_ordered = addresses.reorder('created_at desc')

    return unless addresses_ordered.length > 1

    addresses_ordered.each do |address|
      next if address.master_address_id
      address.find_or_create_master_address
      address.save
    end

    merge_prepped_addresses(addresses_ordered)
  end

  def copy_address(address:, source:, source_donor_account_id: nil)
    attributes = attributes_to_copy(address).merge(
      source_donor_account_id: source_donor_account_id,
      source: source,
      primary_mailing_address: !addresses.any?(&:primary_mailing_address)
    )
    addresses.create!(attributes)
  end

  private

  def attributes_to_copy(address)
    address.attributes.symbolize_keys.except(*FIELDS_TO_NOT_COPY)
  end

  # This aims to be efficient for large numbers of duplicate addresses
  def merge_prepped_addresses(addresses)
    merged = Set.new
    addresses.each do |address|
      next if merged.include?(address)
      dups = addresses.select do |a|
        a.equal_to?(address) && a.id != address.id && !merged.include?(a)
      end
      next if dups.empty?
      dups.each do |dup|
        merged << dup
        address.merge(dup)
      end
    end
  end
end
