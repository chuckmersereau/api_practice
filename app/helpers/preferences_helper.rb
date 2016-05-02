module PreferencesHelper
  include LocalizationHelper

  def salary_organization_select(account_list)
    options_for_select(
      Hash[account_list.designation_organizations.map(&method(:org_option))],
      account_list.salary_organization_id
    )
  end

  private

  def org_option(org)
    currency = org.default_currency_code
    ["#{org.name} (#{currency_symbol(currency)} #{currency})", org.id]
  end
end
