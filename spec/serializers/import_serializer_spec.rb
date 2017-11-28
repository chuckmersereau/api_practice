require 'rails_helper'

describe ImportSerializer do
  let(:import) { build(:csv_import_custom_headers, in_preview: true) }

  subject { ImportSerializer.new(import).as_json }

  describe '#file_url' do
    it 'returns the file url' do
      expect(subject[:file_url]).to end_with('/sample_csv_with_custom_headers.csv')
    end
  end

  describe '#sample_contacts' do
    before do
      import.file_headers_mappings = {
        'church'               => 'church',
        'city'                 => 'city',
        'pledge_amount'        => 'amount',
        'pledge_currency'      => 'currency',
        'pledge_frequency'     => 'frequency',
        'contact_name'         => 'fname',
        'country'              => 'country',
        'email_1'              => 'email-address',
        'first_name'           => 'fname',
        'greeting'             => 'greeting',
        'envelope_greeting'    => 'mailing-greeting',
        'last_name'            => 'lname',
        'likely_to_give'       => 'likely-giver',
        'metro_area'           => 'metro',
        'newsletter'           => 'newsletter',
        'notes'                => 'extra-notes',
        'phone_1'              => 'phone',
        'region'               => 'region',
        'send appeals'         => 'appeals',
        'spouse_email'         => 'Spouse-email-address',
        'spouse_first_name'    => 'Spouse-fname',
        'spouse_last_name'     => 'Spouse-lname',
        'spouse_phone'         => 'Spouse-phone-number',
        'state'                => 'province',
        'status'               => 'status',
        'street'               => 'street',
        'tags'                 => 'tags',
        'website'              => 'website',
        'zip'                  => 'zip-code'
      }

      import.file_constants_mappings = {
        'pledge_currency' => [
          { id: 'CAD', values: ['CAD'] },
          { id: 'USD', values: ['nil'] }
        ],
        'pledge_frequency' => [
          { id: 'Monthly', values: ['Monthly'] },
          { id: '', values: [''] }
        ],
        'likely_to_give' => [
          { id: 'Most Likely', values: ['Yes'] },
          { id: 'Least Likely', values: ['No'] }
        ],
        'newsletter' => [
          { id: 'Both', values: ['Both'] }
        ],
        'send_appeals' => [
          { id: true, values: ['Yes'] },
          { id: false, values: ['No'] }
        ],
        'status' => [
          { id: 'Partner - Financial', values: ['Praying and giving'] },
          { id: 'Partner - Pray', values: ['Praying'] }
        ]
      }

      CsvImport.new(import).update_cached_file_data
    end

    it 'returns the sample contacts' do
      expect(subject[:sample_contacts].size).to eq 3
      expect(subject[:sample_contacts].first[:name]).to eq 'Doe, John'
      expect(subject[:sample_contacts].second[:name]).to eq 'Park, Bob'
      expect(subject[:sample_contacts].third[:name]).to eq 'Man, Joe'
    end
  end
end
