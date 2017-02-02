class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  delegate :activities, :assignable_likely_to_give, :assignable_send_newsletter,
           :pledge_frequencies, :statuses, :codes, :notifications,
           :organizations, to: :object

  type :constant_list
  attributes :activities, :assignable_likely_to_give,
             :assignable_send_newsletter, :pledge_currencies,
             :pledge_frequencies, :statuses, :locales, :notifications,
             :organizations, :currencies

  def currencies
    constants_exhibit.currency_code_symbol_map
  end

  def locales
    constants_exhibit.locale_name_map
  end

  def pledge_currencies
    constants_exhibit.pledge_currencies_code_symbol_map
  end

  private

  def constants_exhibit
    @constants_exhibit ||= exhibit(object)
  end
end
