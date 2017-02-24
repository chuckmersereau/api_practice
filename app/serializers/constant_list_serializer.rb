class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  delegate :activities,
           :assignable_likely_to_give,
           :assignable_locations,
           :assignable_send_newsletter,
           :assignable_statuses,
           :bulk_update_options,
           :codes,
           :next_actions,
           :notifications,
           :organizations,
           :pledge_frequencies,
           :results,
           :statuses,
           to: :object

  delegate :bulk_update_options, to: :constants_exhibit

  type :constant_list

  attributes :activities,
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
