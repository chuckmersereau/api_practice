class Admin::PrimaryAddressFix
  def initialize(contact)
    @contact = contact
  end

  def fix!
    mailing_address = @contact.mailing_address

    # Contact#mailing_address returns Address.new if there is no mailing address
    return if mailing_address.new_record?

    if mailing_address.primary_mailing_address
      make_others_non_primary(mailing_address)
    else
      mailing_address.update(primary_mailing_address: true)
    end

    make_historic_non_primary
  end

  private

  def make_others_non_primary(mailing_address)
    @contact.addresses.where.not(id: mailing_address.id)
      .where(primary_mailing_address: true).find_each do |address|
      # Update each record one-by-one so PaperTrail tracks changes
      address.update(primary_mailing_address: false)
    end
  end

  def make_historic_non_primary
    @contact.addresses.where(historic: true, primary_mailing_address: true)
      .find_each { |address| address.update(primary_mailing_address: false) }
  end
end
