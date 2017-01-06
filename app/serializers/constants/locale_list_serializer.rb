class Constants::LocaleListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  type :locale_list
  attributes :locales

  def locales
    locales_exhibit.locales.map do |name, code|
      [locales_exhibit.display_name(name, code), code]
    end
  end

  def locales_exhibit
    @locales_exhibit ||= exhibit(object)
  end
end
