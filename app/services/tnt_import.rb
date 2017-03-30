class TntImport
  def initialize(import)
    @import = import
    @account_list = @import.account_list
    @user = @import.user
    @designation_profile = @account_list.designation_profiles.first || @user.designation_profiles.first
    @tags_by_contact_id = {}
  end

  def xml
    @xml ||= TntImport::XmlReader.new(@import).parsed_xml
  end

  def import
    @import.file.cache_stored_file!
    return false unless xml.present?

    contact_ids_by_tnt_contact_id = import_contacts

    import_referrals(contact_ids_by_tnt_contact_id)
    import_tasks(contact_ids_by_tnt_contact_id)

    contact_ids_by_tnt_appeal_id = import_history(contact_ids_by_tnt_contact_id)

    import_offline_org_gifts(contact_ids_by_tnt_contact_id)
    import_settings
    import_appeals(contact_ids_by_tnt_appeal_id)
    import_pledges

    false
  ensure
    CarrierWave.clean_cached_files!
  end

  private

  def import_contacts
    TntImport::ContactsImport.new(@import, @designation_profile, xml)
                             .import_contacts
  end

  def import_referrals(tnt_contacts)
    rows = xml.tables['Contact']
    TntImport::ReferralsImport.new(tnt_contacts, rows).import
  end

  def import_tasks(tnt_contacts = {})
    TntImport::TasksImport.new(@account_list, tnt_contacts, xml).import
  end

  def import_history(tnt_contacts = {})
    TntImport::HistoryImport.new(@account_list, tnt_contacts, xml).import_history
  end

  def import_offline_org_gifts(tnt_contacts)
    TntImport::GiftsImport.new(@account_list, tnt_contacts, xml, @import).import
  end

  def import_settings
    TntImport::SettingsImport.new(@account_list, xml, @import.override?).import
  end

  def import_appeals(contact_ids_by_tnt_appeal_id)
    TntImport::AppealsImport.new(@account_list, contact_ids_by_tnt_appeal_id, xml)
                            .import
  end

  def import_pledges
    TntImport::PledgesImport.new(@account_list, @import, xml).import
  end
end
