class DonationImports::Base
  attr_reader :organization_account, :organization

  def initialize(organization_account)
    @organization_account = organization_account
    @organization = organization_account.organization
  end

  # Data server supports two date formats, try both of those,
  # as I work on different donation integrations, this will probably have to be moved to a module.

  def parse_date(date_object)
    return date_object.to_date if date_object.is_a?(Date) || date_object.is_a?(Time)

    extract_date_from_string(date_object, '%Y-%m-%d') || extract_date_from_string(date_object, '%m/%d/%Y')
  end

  private

  def extract_date_from_string(date_object, date_format)
    Date.strptime(date_object, date_format)
  rescue ArgumentError
    nil
  end
end
