class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  delegate :activities, :assignable_likely_to_give, :assignable_send_newsletter,
           :pledge_frequencies, :statuses, :codes, to: :object

  type :constant_list
  attributes :activities, :assignable_likely_to_give,
             :assignable_send_newsletter, :pledge_currencies,
             :pledge_frequencies, :statuses, :locales, :notifications,
             :organizations, :currencies

  def currencies
    constants_exhibit.currency_code_symbol_pairs
  end

  def locales
    constants_exhibit.locale_name_pairs
  end

  def notifications
    constants_exhibit.notification_description_pairs
  end

  def organizations
    constants_exhibit.organization_name_pairs
  end

  def pledge_currencies
    constants_exhibit.pledge_currencies_code_symbol_pairs
  end

  private

  def constants_exhibit
    @constants_exhibit ||= exhibit(object)
  end
end
