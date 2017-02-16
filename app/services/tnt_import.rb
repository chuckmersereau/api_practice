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
    return unless xml.present?

    tnt_contacts = import_contacts
    import_referrals(tnt_contacts)
    import_tasks(tnt_contacts)
    _history, contacts_by_tnt_appeal_id = import_history(tnt_contacts)

    import_offline_org_gifts(tnt_contacts)
    import_settings
    import_appeals(contacts_by_tnt_appeal_id)
  ensure
    CarrierWave.clean_cached_files!
  end

  private

  def import_contacts
    TntImport::ContactsImport.new(@import, @designation_profile, xml)
                             .import_contacts
  end

  def import_referrals(tnt_contacts)
    rows = Array.wrap(xml['Contact']['row'])
    TntImport::ReferralsImport.new(tnt_contacts, rows).import
  end

  def import_tasks(tnt_contacts = {})
    TntImport::TasksImport.new(@account_list, tnt_contacts, xml).import
  end

  def import_history(tnt_contacts = {})
    TntImport::HistoryImport.new(@account_list, tnt_contacts, xml).import_history
  end

  def import_offline_org_gifts(tnt_contacts)
    TntImport::GiftsImport.new(@account_list, tnt_contacts, xml).import
  end

  def import_settings
    TntImport::SettingsImport.new(@account_list, xml, @import.override?).import
  end

  def import_appeals(contacts_by_tnt_appeal_id)
    TntImport::AppealsImport.new(@account_list, contacts_by_tnt_appeal_id, xml)
                            .import
  end
end
