require 'rails_helper'

RSpec.describe CsvExport, type: :service do
  describe '#self.mailing_addresses' do
    it 'does not cause an error or give an empty string' do
      contact = create(:contact, name: 'Doe, John', send_newsletter: 'Both')
      contact.addresses << create(:address)
      account_list = create(:account_list)
      account_list.contacts << contact
      csv_rows =
        CSV.parse(described_class.mailing_addresses(ContactFilter.new(newsletter: 'address').filter(account_list.contacts, account_list)))
      expect(csv_rows.size).to eq(2)
      csv_rows.each_with_index do |row, index|
        expect(row[0]).to eq('Contact Name') if index.zero?
        expect(row[0]).to eq('Doe, John') if index == 1
        expect(row[0]).to be_nil if index == 2
      end
    end
  end
end
