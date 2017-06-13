class Api::V2::Contacts::People::LinkedinAccountsPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {}.freeze
  FIELD_ASSOCIATION_MAPPING = {}.freeze

  private

  def serializer_class
    Person::LinkedinAccountSerializer
  end
end
