class DonationImports::Siebel < DonationImports::Base
  delegate :requires_credentials?, to: :class

  def import_all(date_from = 1.year.ago)
    import_profiles
    import_donors
    import_donations(date_from)
  end

  def self.requires_credentials?
    false
  end

  def import_profiles
    ProfileImporter.new(self).import_profiles
  end

  private

  def import_donors
    DonorImporter.new(self).import_donors
  end

  def import_donations(date_from)
    DonationImporter.new(self).import_donations(start_date: date_from)
  end
end
