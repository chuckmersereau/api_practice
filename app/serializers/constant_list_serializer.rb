class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  delegate :activities,
           :alert_frequencies,
           :assignable_likely_to_give,
           :assignable_locations,
           :assignable_send_newsletter,
           :assignable_statuses,
           :bulk_update_options,
           :codes,
           :mobile_alert_frequencies,
           :next_actions,
           :notifications,
           :organizations,
           :organizations_attributes,
           :pledge_frequencies,
           :results,
           :statuses,
           :csv_import,
           :sources,
           :tnt_import,
           to: :object

  delegate :bulk_update_options,
           :notification_translated_hashes,
           to: :constants_exhibit

  type :constant_list

  attributes :activities,
             :activity_hashes,
             :alert_frequencies,
             :assignable_likely_to_give,
             :assignable_likely_to_give_hashes,
             :assignable_locations,
             :assignable_location_hashes,
             :assignable_send_newsletter,
             :assignable_send_newsletter_hashes,
             :assignable_statuses,
             :bulk_update_options,
             :csv_import,
             :dates,
             :languages,
             :locales,
             :mobile_alert_frequencies,
             :next_actions,
             :notifications,
             :notification_translated_hashes,
             :organizations,
             :organizations_attributes,
             :pledge_currencies,
             :pledge_frequencies,
             :pledge_frequency_hashes,
             :results,
             :send_appeals_hashes,
             :sources,
             :statuses,
             :status_hashes,
             :tnt_import

  def locales
    constants_exhibit.locale_name_map
  end

  def pledge_currencies
    constants_exhibit.pledge_currencies_code_symbol_map
  end

  def activity_hashes
    constants_exhibit.activity_translated_hashes
  end

  def assignable_likely_to_give_hashes
    constants_exhibit.assignable_likely_to_give_translated_hashes
  end

  def assignable_send_newsletter_hashes
    constants_exhibit.assignable_send_newsletter_translated_hashes
  end

  def status_hashes
    constants_exhibit.status_translated_hashes
  end

  def pledge_frequency_hashes
    constants_exhibit.pledge_frequency_translated_hashes
  end

  def assignable_location_hashes
    constants_exhibit.assignable_location_translated_hashes
  end

  def dates
    constants_exhibit.date_formats_map
  end

  def languages
    constants_exhibit.languages_map
  end

  def send_appeals_hashes
    constants_exhibit.send_appeals_translated_hashes
  end

  private

  def constants_exhibit
    @constants_exhibit ||= object.to_exhibit
  end
end
