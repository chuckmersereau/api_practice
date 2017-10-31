# In version 3.2, TNT renamed the "Appeal" table to "Campaign".

class TntImport::AppealsImport
  include Concerns::TntImport::AppealHelpers

  def initialize(account_list, contact_ids_by_tnt_appeal_id, xml)
    @account_list = account_list
    @contact_ids_by_tnt_appeal_id = contact_ids_by_tnt_appeal_id
    @xml = xml
    @xml_tables = xml.tables
  end

  def import
    appeals_by_tnt_id = find_or_create_appeals_by_tnt_id

    appeals_by_tnt_id.each do |appeal_tnt_id, appeal|
      contact_ids = contact_ids_by_tnt_appeal_id[appeal_tnt_id] || []
      appeal.bulk_add_contacts(contact_ids: contact_ids)
    end
  end

  private

  attr_reader :xml_tables, :contact_ids_by_tnt_appeal_id

  def find_or_create_appeals_by_tnt_id
    return {} unless xml_tables[appeal_table_name].present?

    appeals = {}
    xml_tables[appeal_table_name].each do |row|
      appeal = @account_list.appeals.find_or_initialize_by(tnt_id: row['id'])
      appeal.attributes = {
        created_at: row['LastEdit'],
        name: row['Description'],
        active: row['Active'] || true,
        amount: row['SpecialGoal'],
        monthly_amount: row['MonthlyGoal']
      }
      appeal.save
      appeals[row['id']] = appeal
    end
    appeals
  end
end
