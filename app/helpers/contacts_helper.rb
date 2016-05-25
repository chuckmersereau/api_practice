module ContactsHelper
  def contact_locale_filter_options(account_list)
    options = account_list.contact_locales.select(&:present?).map do |locale|
      [_(MailChimpAccount::Locales::LOCALE_NAMES[locale]), locale]
    end

    options_for_select(
      [[_('-- Any --'), ''], [_('-- Unspecified --'), 'null']] +
      options
    )
  end
end
