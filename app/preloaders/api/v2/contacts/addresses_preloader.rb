class Api::V2::Contacts::AddressesPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {}.freeze
  FIELD_ASSOCIATION_MAPPING = { geo: :master_address }.freeze
end
