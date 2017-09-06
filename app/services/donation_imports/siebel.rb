class DonationImports::Siebel < DonationImports::Base
  def import_data
    import_profiles
    import_donors
    import_donations
  end

  def self.requires_username_and_password?
    false
  end

  private

  def import_profiles
    ProfileImporter.new(self).import_profiles
  end

  def import_donors
    DonorImporter.new(self).import_donors
  end

  def import_donations
    DonationImporter.new(self).import_donations(start_date: 1.year.ago)
  end
end
