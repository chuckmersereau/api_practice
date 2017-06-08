# In TNT a Pledge is called a "Promise".

class TntImport::PledgesImport
  include Concerns::TntImport::AppealHelpers
  include Concerns::TntImport::DateHelpers

  DEFAULT_CURRENCY_CODE = 'USD'.freeze

  def initialize(account_list, import, xml)
    @account_list = account_list
    @import = import
    @xml = xml
  end

  def import
    return {} unless @xml.tables['Promise']
    Array.wrap(@xml.tables['Promise']).each do |row|
      import_pledge(row)
    end
  end

  private

  def import_pledge(row)
    @account_list.pledges.create(amount: row['Amount'],
                                 amount_currency: find_tnt_currency_code_for_row(row),
                                 appeal: find_mpdx_appeal_for_row(row),
                                 contact: find_mpdx_contact_for_row(row),
                                 expected_date: parse_date(row['DateDue'], @import.user))
  end

  def find_mpdx_contact_for_row(row)
    return unless row['ContactID'].present?
    @account_list.contacts.where(tnt_id: row['ContactID']).first
  end

  def find_mpdx_appeal_for_row(row)
    return unless row[appeal_id_name].present?
    @account_list.appeals.where(tnt_id: row[appeal_id_name]).first
  end

  def find_tnt_currency_code_for_row(row)
    currency_id = row['CurrencyID']
    return DEFAULT_CURRENCY_CODE unless currency_id && @xml.tables['Currency']
    found_currency_row = @xml.tables['Currency'].detect { |currency_row| currency_row['id'] == currency_id }
    found_currency_row.try(:[], 'Code').presence || DEFAULT_CURRENCY_CODE
  end
end
