class AddressExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Address'
  end

  def to_s
    to_google
  end

  def to_html
    case country
    when 'United States', nil, '', 'USA', 'United States of America'
      [street ? street.gsub(/\n/, '<br />') : nil, [[city, state].select(&:present?).join(', '), postal_code].select(&:present?).join(' ')].select(&:present?).join('<br />').html_safe
    else
      to_google
    end
  end

  def to_i18n_html
    i18n = to_snail
    i18n = i18n.gsub(country.upcase, country) if country.present?
    i18n.gsub("\n", '<br>').html_safe
  end

  def to_google
    [street, city, state, postal_code, country].select(&:present?).join(', ')
  end

  def user_friendly_source
    case source
    when 'DataServer', 'Siebel' then _('Donor system')
    when 'GoogleImport' then _('Google import')
    when 'GoogleContactsSync' then _('Google sync')
    when 'TntImport'  then _('Tnt import')
    when Address::MANUAL_SOURCE then _('Manual entry')
    else source
    end
  end

  def address_change_email_body
    donor_info = if source_donor_account.present?
                   _('"%{name}" (donor #%{account_number})').localize % {
                     name: source_donor_account.name,
                     account_number: source_donor_account.account_number
                   }
                 else
                   "\"#{addressable.name}\""
                 end

    [
      _('Dear Donation Services') + ",\n\n",
      _('One of my donors, %{donor} has a new current address.').localize % { donor: donor_info } + "\n\n",
      _('Please update their address to') + ":\n\n",
      _('REPLACE WITH NEW STREET') + "\n",
      _('REPLACE WITH NEW CITY, STATE, ZIP') + "\n\n",
      _('Thanks!') + "\n\n"
    ].join
  end
end
