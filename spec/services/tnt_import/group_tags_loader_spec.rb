require 'rails_helper'

describe TntImport::GroupTagsLoader do
  let(:import) { create(:tnt_import, override: true) }
  let(:tnt_import) { TntImport.new(import) }
  let(:xml) { tnt_import.xml }

  context 'version 3.2 and higher' do
    before { import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

    it 'expects the right xml version' do
      expect(xml.version).to eq 3.2
    end

    describe '.tags_by_tnt_contact_id' do
      it 'returns a hash of expected tags grouped by contat id' do
        expect(TntImport::GroupTagsLoader.tags_by_tnt_contact_id(xml)).to eq('748459734' => ['Call-this-summer', 'Group-5', 'Pacific-Time-Zone',
                                                                                             'Group-9', 'Green-Light', 'Group-6', 'Yet-Another-Group',
                                                                                             'Group-7', 'Red-Light', 'Increase-Project', 'Increase-Project\\Ask',
                                                                                             'Group-Category', 'Group-Category\\My-Big-Named-Group-for-Summer-02',
                                                                                             'Group-3', 'Group-Set-1', 'Group-Set-1\\Group2',
                                                                                             'Group-Category\\My-Big-Named-Group-for-Summer-01',
                                                                                             'Increase-Project\\Call-Back', 'Increase-Project\\Ask-Again',
                                                                                             'Group-Set-1\\Group1', 'Group-Category\\My-Big-Named-Group-for-Summer-03',
                                                                                             'Group-4', 'Really-Important-Group', 'Send-Christmas-Cookies', 'Group-8',
                                                                                             'Increase-Project\\Try-a-third-time', '2017-Increase-Campaign',
                                                                                             '2017-Increase-Campaign\\1-Top-Level'],
                                                                             '1' => ['2017-Increase-Campaign', '2017-Increase-Campaign\\4-Prospect'],
                                                                             '748459735' => ['2017-Increase-Campaign', '2017-Increase-Campaign\\4-Prospect'])
      end
    end
  end

  context 'version 3.1 and lower' do
    before { import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_groups.xml')) }

    it 'expects the right xml version' do
      expect(xml.version).to eq 3.0
    end

    describe '.tags_by_tnt_contact_id' do
      it 'returns a hash of expected tags grouped by contat id' do
        expect(TntImport::GroupTagsLoader.tags_by_tnt_contact_id(xml)).to eq('1' => ['Group-with-Dave-comma', 'Category-1-comma', 'Testers'])
      end
    end
  end
end
