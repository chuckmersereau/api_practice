# Historically the Tnt import did not import gifts (donations) from the Tnt xml for online orgs
# (because they are imported from the org api, like Siebel).
# Because the gifts were not imported from the xml they were not associated to appeals.
# Recently the Tnt import was updated to import gifts from the Tnt xml, so that we can associate them to appeals.
# This job will re-run the appeal, pledge, and gift part of the Tnt import.
# We will run it on accounts that did not have their gifts associated to appeals.

class ImportGiftsAndAppealsFromTntWorker
  include Sidekiq::Worker
  include Concerns::TntImport::AppealHelpers

  sidekiq_options queue: :api_import_gifts_and_appeals_from_tnt_worker

  def perform(import_id)
    @import = Import.joins(:account_list).where(id: import_id, source: 'tnt').first
    return unless import && account_list && account_list.appeals.any?
    perform_import
  end

  private

  attr_accessor :import

  def account_list
    @account_list ||= @import.account_list
  end

  def tnt_import
    @tnt_import ||= TntImport.new(import)
  end

  def xml
    @xml ||= tnt_import.xml
  end

  def contact_ids_by_tnt_contact_id
    tnt_ids = import.account_list.contacts.where.not(tnt_id: nil).pluck(:id, :tnt_id)
    @contact_ids_by_tnt_contact_id ||= tnt_ids.each_with_object({}) do |(mpdx_id, tnt_id), hash|
      hash[tnt_id.to_s] = mpdx_id
    end
  end

  def tnt_appeal_ids
    @tnt_appeal_ids ||= xml.tables[appeal_table_name].collect { |row| row['id'] }
  end

  def contact_ids_by_tnt_appeal_id
    @contact_ids_by_tnt_appeal_id ||= tnt_appeal_ids.each_with_object({}).each do |tnt_appeal_id, hash|
      appeal = account_list.appeals.find_by(tnt_id: tnt_appeal_id)
      contact_ids = appeal&.contacts&.pluck(:id) || []
      hash[tnt_appeal_id] = contact_ids
    end
  end

  def perform_import
    @import.file.cache_stored_file!
    TntImport::AppealsImport.new(account_list, contact_ids_by_tnt_appeal_id, xml).import
    TntImport::PledgesImport.new(account_list, import, xml).import
    TntImport::GiftsImport.new(account_list, contact_ids_by_tnt_contact_id, xml, import).import
  end
end
