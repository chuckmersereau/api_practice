class AddressExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Address'
  end

  def to_s
    to_google
  end

  def to_google
    [street, city, state, postal_code, country].select(&:present?).join(', ')
  end

  def user_friendly_source
    case source
    when 'DataServer', 'Siebel' then _('Donor system')
    when 'GoogleImport' then _('Google import')
    when 'GoogleContactsSync' then _('Google sync')
    when TntImport::Source then _('Tnt import')
    when Address::MANUAL_SOURCE then _('Manual entry')
    else source
    end
  end

  def address_change_email_body
    donor_info = if source_donor_account.present?
                   details = { name: source_donor_account.name, account_number: source_donor_account.account_number }
                   format(_('"%{name}" (donor #%{account_number})'), details)
                 else
                   "\"#{addressable.name}\""
                 end

    [
      _('Dear Donation Services') + ",\n\n",
      format(_('One of my donors, %{donor} has a new current address.'), donor: donor_info) + "\n\n",
      _('Please update their address to') + ":\n\n",
      _('REPLACE WITH NEW STREET') + "\n",
      _('REPLACE WITH NEW CITY, STATE, ZIP') + "\n\n",
      _('Thanks!') + "\n\n"
    ].join
  end
end
