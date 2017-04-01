require 'rails_helper'

describe ImportSerializer do
  let(:import) { build(:csv_import_custom_headers, in_preview: true) }

  subject { ImportSerializer.new(import).as_json }

  it { should include :account_list_id }
  it { should include :created_at }
  it { should include :file_constants }
  it { should include :file_constants_mappings }
  it { should include :file_headers }
  it { should include :file_headers_mappings }
  it { should include :file_url }
  it { should include :group_tags }
  it { should include :groups }
  it { should include :import_by_group }
  it { should include :in_preview }
  it { should include :override }
  it { should include :sample_contacts }
  it { should include :source }
  it { should include :tags }
  it { should include :updated_at }
  it { should include :updated_in_db_at }

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
        'commitment_amount'    => 'amount',
        'commitment_currency'  => 'currency',
        'commitment_frequency' => 'frequency',
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
        'commitment_currency' => {
          'cad' => 'CAD',
          'usd' => nil
        },
        'commitment_frequency' => {
          '1_0' => 'Monthly',
          nil => nil
        },
        'likely_to_give' => {
          'most_likely' => 'Yes',
          'least_likely' => 'No'
        },
        'newsletter' => {
          'both' => 'Both'
        },
        'send_appeals' => {
          'true' => 'Yes',
          'false' => 'No'
        },
        'status' => {
          'partner_financial' => 'Praying and giving',
          'partner_pray' => 'Praying'
        }
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
