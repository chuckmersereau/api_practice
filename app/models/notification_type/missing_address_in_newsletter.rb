class NotificationType::MissingAddressInNewsletter < NotificationType::MissingContactInfo
  def missing_info_filter(contacts)
    contacts.where(send_newsletter: %w(Both Physical))
            .joins('LEFT JOIN addresses '\
             "ON addresses.addressable_type = 'Contact' "\
             'AND addresses.addressable_id = contacts.id '\
             "AND (addresses.historic = 'f' OR addresses.historic IS NULL)"\
             "AND addresses.deleted = 'f'")
            .where(addresses: { id: nil })
  end

  def task_description_template
    '%{contact_name} is on the physical newsletter but lacks a current mailing address.'
  end
end
