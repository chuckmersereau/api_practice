class CsvExport
  def self.mailing_addresses(contacts)
    render({
             'Contact Name' => :name,
             'Greeting' => :greeting,
             'Envelope Greeting' => :envelope_greeting,
             'Mailing Street Address' => :csv_street,
             'Mailing City' => :city,
             'Mailing State' => :state,
             'Mailing Postal Code' => :postal_code,
             'Mailing Country' => :csv_country,
             'Address Block' => :address_block
           }, contacts)
  end

  def self.render(field_mapping, contacts)
    CSV.generate do |csv|
      csv << field_mapping.keys
      contacts.each do |contact|
        csv << field_mapping.values.map { |method| ContactExhibit.new(contact, nil).send(method) }
      end
    end
  end
end
