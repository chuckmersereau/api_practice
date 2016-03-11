class TntImport::AddressesBuilder
  class << self
    def build_address_array(row, contact = nil, override = true)
      addresses = []
      %w(Home Business Other).each_with_index do |location, i|
        street = row["#{location}StreetAddress"]
        city = row["#{location}City"]
        state = row["#{location}State"]
        postal_code = row["#{location}PostalCode"]
        country = row["#{location}Country"] == 'United States of America' ? 'United States' : row["#{location}Country"]
        next unless [street, city, state, postal_code].any?(&:present?)
        primary_address = false
        primary_address = row['MailingAddressType'].to_i == (i + 1) if override
        if primary_address && contact
          contact.addresses.each do |address|
            next if address.street == street && address.city == city && address.state == state && address.postal_code == postal_code && address.country == country
            address.primary_mailing_address = false
            address.save
          end
        end
        addresses << {  street: street, city: city, state: state, postal_code: postal_code, country: country,
                        location: location,  region: row['Region'], primary_mailing_address: primary_address,
                        source: 'TntImport'  }
      end
      addresses
    end
  end
end
