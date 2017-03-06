require 'rails_helper'

describe ImportSerializer do
  let(:import) { build(:csv_import_custom_headers, in_preview: true) }

  subject { ImportSerializer.new(import).as_json }

  it { should include :account_list_id }
  it { should include :file }
  it { should include :file_headers }
  it { should include :groups }
  it { should include :group_tags }
  it { should include :import_by_group }
  it { should include :in_preview }
  it { should include :override }
  it { should include :source }
  it { should include :tags }

  it { should include :created_at }
  it { should include :updated_at }
  it { should include :updated_in_db_at }

  describe '#file_headers' do
    it 'returns the file_headers as an array' do
      expect(subject[:file_headers]).to eq %w(
        name
        fname
        lname
        spouse_fname
        spouse_lname
        greeting
        envelope_greeting
        street
        city
        state
        zipcode
        country
        status
        amount
        frequency
        newsletter
        received
        tags
        email
        spouse_email
        phone
        spouse_phone
        note)
    end
  end
end
