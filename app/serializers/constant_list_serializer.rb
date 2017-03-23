class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  delegate :assignable_locations,
           :assignable_statuses,
           :bulk_update_options,
           :codes,
           :next_actions,
           :organizations,
           :pledge_frequencies,
           :results,
           to: :object

  delegate :bulk_update_options, to: :constants_exhibit

  type :constant_list

  attributes :activities,
             :alert_frequencies,
             :assignable_locations,
             :assignable_likely_to_give,
             :assignable_send_newsletter,
             :assignable_statuses,
             :bulk_update_options,
             :dates,
             :languages,
             :next_actions,
             :pledge_currencies,
             :pledge_frequencies,
             :results,
             :statuses,
             :locales,
             :notifications,
             :organizations

  def locales
    constants_exhibit.locale_name_map
  end

  def pledge_currencies
    constants_exhibit.pledge_currencies_code_symbol_map
  end

  def activities
    constants_exhibit.activities_translated
  end

  def assignable_likely_to_give
    constants_exhibit.assignable_likely_to_give_translated
  end

  def assignable_send_newsletter
    constants_exhibit.assignable_send_newsletter_translated
  end

  def statuses
    constants_exhibit.statuses_translated
  end

  def notifications
    constants_exhibit.notifications_translated
  end

  def dates
    constants_exhibit.date_formats_map
  end

  def languages
    constants_exhibit.languages_map
  end

  private

  def constants_exhibit
    @constants_exhibit ||= exhibit(object)
  end
end
