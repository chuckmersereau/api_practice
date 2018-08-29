class ConstantListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper
  type :constant_list

  delegate :activities,
           :alert_frequencies,
           :assignable_likely_to_give,
           :assignable_locations,
           :assignable_send_newsletter,
           :assignable_statuses,
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
           :dates,
           :languages,
           :locales,
           :pledge_currencies,
           :pledge_received,
           :activity_hashes,
           :assignable_likely_to_give_hashes,
           :assignable_location_hashes,
           :assignable_send_newsletter_hashes,
           :assignable_status_hashes,
           :bulk_update_option_hashes,
           :notification_hashes,
           :pledge_currency_hashes,
           :pledge_frequency_hashes,
           :pledge_received_hashes,
           :send_appeals_hashes,
           :status_hashes,
           to: :constants_exhibit

  attributes :activities,
             :alert_frequencies,
             :assignable_likely_to_give,
             :assignable_locations,
             :assignable_send_newsletter,
             :assignable_statuses,
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
             :bulk_update_options,
             :dates,
             :languages,
             :locales,
             :pledge_currencies,
             :pledge_received,
             :activity_hashes,
             :assignable_likely_to_give_hashes,
             :assignable_location_hashes,
             :assignable_send_newsletter_hashes,
             :assignable_status_hashes,
             :bulk_update_option_hashes,
             :notification_hashes,
             :notification_translated_hashes,
             :pledge_currency_hashes,
             :pledge_frequency_hashes,
             :pledge_received_hashes,
             :send_appeals_hashes,
             :status_hashes

  # This was mistakenly published on the Public API
  # It is here to maintain compatibility with old clients
  def notification_translated_hashes
    constants_exhibit.notification_hashes
  end

  private

  def constants_exhibit
    @constants_exhibit ||= object.to_exhibit
  end
end
