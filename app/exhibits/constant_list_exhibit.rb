class ConstantListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'ConstantList'
  end

  def locale_name_map
    Hash[
      locales.map { |name, code| [code, locale_display_name(name, code)] }
    ]
  end

  def pledge_currencies_code_symbol_map
    Hash[
      codes.map { |c| [c, currency_code_and_symbol(c)] }
    ]
  end

  def currency_code_and_symbol(code)
    format '%s (%s)', code, currency_symbol(code)
  end

  def locale_display_name(name, code)
    format '%s (%s)', name, code
  end
end
