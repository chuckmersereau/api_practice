class TntImport::ContactsImport
  def initialize(import, designation_profile, xml)
    @import = import
    @account_list = import.account_list
    @override = import.override?
    @tags_for_all = Array.wrap(import.tags)
    @designation_profile = designation_profile
    @xml = xml
    @xml_tables = xml.tables
  end

  def import_contacts
    donors_by_tnt_id = donor_accounts_by_tnt_contact_id

    contact_id_by_tnt_contact_id = {}

    @xml_tables['Contact'].each do |row|
      tnt_id = row['id']
      tags = all_tags_for_tnt_contact_id(tnt_id)
      donor_accounts = donors_by_tnt_id[tnt_id]
      contact = import_contact(row, tags.compact, donor_accounts)
      contact_id_by_tnt_contact_id[tnt_id] = contact.id if contact.id
    end

    contact_id_by_tnt_contact_id
  end

  private

  def all_tags_for_tnt_contact_id(tnt_id)
    (@tags_for_all +
      group_tags_for_tnt_contact_id(tnt_id) +
      contact_tags_for_tnt_contact_id(tnt_id)).uniq
  end

  def group_tags_for_tnt_contact_id(tnt_id)
    @group_tags_by_tnt_contact_id ||= TntImport::GroupTagsLoader.tags_by_tnt_contact_id(@xml)
    Array.wrap(@group_tags_by_tnt_contact_id[tnt_id])
  end

  def contact_tags_for_tnt_contact_id(tnt_id)
    @contact_tags_for_tnt_contact_id ||= TntImport::ContactTagsLoader.new(@xml).tags_by_tnt_contact_id
    Array.wrap(@contact_tags_for_tnt_contact_id[tnt_id])
  end

  def import_contact(row, tags, donor_accounts)
    TntImport::ContactImport.new(@import, tags, donor_accounts, languages)
                            .import_contact(row)
  end

  def donor_accounts_by_tnt_contact_id
    @donor_accounts_by_contact_id ||=
      TntImport::DonorAccountsImport.new(@xml, orgs_by_tnt_id).import
  end

  def orgs_by_tnt_id
    TntImport::OrgsFinder
      .orgs_by_tnt_id(@xml, @designation_profile.try(:organization))
  end

  def languages
    @xml.tables['NewsletterLang']
  end
end
