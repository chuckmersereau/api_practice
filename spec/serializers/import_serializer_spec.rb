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
        'Church'               => 'church',
        'City'                 => 'city',
        'Commitment Amount'    => 'amount',
        'Commitment Currency'  => 'currency',
        'Commitment Frequency' => 'frequency',
        'Contact Name'         => 'fname',
        'Country'              => 'country',
        'Do Not Import?'       => 'skip',
        'Email 1'              => 'email-address',
        'First Name'           => 'fname',
        'Greeting'             => 'greeting',
        'Envelope Greeting'    => 'mailing-greeting',
        'Last Name'            => 'lname',
        'Likely To Give'       => 'likely-giver',
        'Metro Area'           => 'metro',
        'Newsletter'           => 'newsletter',
        'Notes'                => 'extra-notes',
        'Phone 1'              => 'phone',
        'Region'               => 'region',
        'Send Appeals?'        => 'appeals',
        'Spouse Email'         => 'Spouse-email-address',
        'Spouse First Name'    => 'Spouse-fname',
        'Spouse Last Name'     => 'Spouse-lname',
        'Spouse Phone'         => 'Spouse-phone-number',
        'State'                => 'province',
        'Status'               => 'status',
        'Street'               => 'street',
        'Tags'                 => 'tags',
        'Website'              => 'website',
        'Zip'                  => 'zip-code'
      }

      import.file_constants_mappings = {
        'Commitment Currency' => {
          'CAD' => 'CAD',
          'USD' => nil
        },
        'Commitment Frequency' => {
          '1.0' => 'Monthly',
          nil => nil
        },
        'Do Not Import?' => {
          'true' => 'Yes',
          'false' => ['No', nil]
        },
        'Likely To Give' => {
          'Most Likely' => 'Yes',
          'Least Likely' => 'No'
        },
        'Newsletter' => {
          'Both' => 'Both'
        },
        'Send Appeals?' => {
          'true' => 'Yes',
          'false' => 'No'
        },
        'Status' => {
          'Partner - Financial' => 'Praying and giving',
          'Partner - Pray' => 'Praying'
        }
      }

      CsvImport.new(import).update_cached_file_data
    end

    it 'returns the sample contacts' do
      expect(subject[:sample_contacts].size).to eq 2
      expect(subject[:sample_contacts].first[:name]).to eq 'John'
      expect(subject[:sample_contacts].second[:name]).to eq 'Joe'
    end
  end
end
