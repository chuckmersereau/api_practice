class Api::V2::Contacts::People::WebsitesPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {}.freeze
  FIELD_ASSOCIATION_MAPPING = {}.freeze

  private

  def serializer_class
    Person::WebsiteSerializer
  end
end
