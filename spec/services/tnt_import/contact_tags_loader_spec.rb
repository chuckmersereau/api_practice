require 'rails_helper'

describe TntImport::ContactTagsLoader do
  let(:import) { create(:tnt_import, override: true) }
  let(:tnt_import) { TntImport.new(import) }
  let(:xml) { tnt_import.xml }

  before { import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

  describe '.tags_by_tnt_contact_id' do
    it 'returns a hash of expected tags grouped by contat id' do
      expect(TntImport::ContactTagsLoader.new(xml).tags_by_tnt_contact_id).to eq('1' => [], '748459734' => ['UserLabel1 - ParrUser1',
                                                                                                            'UserLabel2 - ParrUser2',
                                                                                                            'UserLabel3 - ParrUser3',
                                                                                                            'UserLabel4 - ParrUser4'],
                                                                                 '748459735' => [])
    end
  end
end
