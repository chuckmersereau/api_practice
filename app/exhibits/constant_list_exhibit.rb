class ConstantListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'ConstantList'
  end

  def currency_code_symbol_pairs
    codes.map do |code|
      [currency_code_and_symbol(code), code]
    end
  end

  def locale_name_pairs
    locales.map do |name, code|
      [locale_display_name(name, code), code]
    end
  end

  def notification_description_pairs
    notifications.map do |id, notification|
      [notification.description, id]
    end.sort_by(&:first)
  end

  def organization_name_pairs
    organizations.map do |id, organization|
      [organization.name, id]
    end.sort_by(&:first)
  end

  def pledge_currencies_code_symbol_pairs
    codes.map { |c| [currency_code_and_symbol(c), c] }
  end

  def currency_code_and_symbol(code)
    format '%s (%s)', code, currency_symbol(code)
  end

  def locale_display_name(name, code)
    format '%s (%s)', name, code
  end
end
