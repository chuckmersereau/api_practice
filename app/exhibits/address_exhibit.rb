class AddressExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Address'
  end

  def to_s() to_google; end

  def to_html
    case country
    when 'United States', nil, '', 'USA', 'United States of America'
      [street ? street.gsub(/\n/, '<br />') : nil, [[city, state].select(&:present?).join(', '), postal_code].select(&:present?).join(' ')].select(&:present?).join('<br />').html_safe
    else
      to_google
    end
  end

  def to_google
    [street, city, state, postal_code, country].select(&:present?).join(', ')
  end

  def user_friendly_source
    case source
    when 'DataServer', 'Siebel' then 'Donor system'
    when 'GoogleImport' then 'Google import'
    when 'GoogleContactsSync'  then 'Google sync'
    when 'TntImport'  then 'Tnt import'
    when Address::MANUAL_SOURCE then  'Manual entry'
    else source
    end
  end

  def address_change_email_body
    if source_donor_account.present?
      donor_info = "\"#{source_donor_account.name}\" (donor ##{source_donor_account.account_number})"
    else
      donor_info = "\"#{addressable.name}\""
    end

    "Dear Donation Services,\n\n"\
    "One of my donors, #{donor_info} has a new current address.\n\n"\
    "Please update their address to:\n\n"\
    "REPLACE WITH NEW STREET\n"\
    "REPLACE WITH NEW CITY, STATE, ZIP\n\n"\
    "Thanks!\n\n"
  end
end
