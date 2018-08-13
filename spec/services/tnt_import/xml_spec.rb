require 'spec_helper'

describe TntImport::Xml do
  let(:tnt_import) { FactoryBot.build_stubbed(:tnt_import, override: true) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }

  describe 'initialize' do
    it 'initializes' do
      expect(xml).to be_a TntImport::Xml
    end
  end

  describe '#tables' do
    it 'returns parsed xml as a hash' do
      expect(xml.tables).to be_a Hash
      expect(xml.tables.keys).to eq %w(Appeal
                                       Contact
                                       Designation
                                       Group
                                       GroupContact
                                       History
                                       HistoryContact
                                       HistoryResult
                                       LikelyToGive
                                       Login
                                       LoginProfile
                                       LoginProfileDesignation
                                       PendingAction
                                       Picture
                                       Property
                                       Region
                                       RegionLocation
                                       Task
                                       TaskContact
                                       TaskReason
                                       TaskType
                                       Currency)
    end
  end

  describe '#version' do
    it 'returns parsed version as a float' do
      expect(xml.version).to be_a Float
      expect(xml.version).to eq 3.0
    end
  end

  describe '#find' do
    it 'finds row by id' do
      appeal_id = xml.tables['Contact'].last['id']

      expect(xml.find('Contact', appeal_id)).to eq xml.tables['Contact'].last
    end

    it 'finds row by attributes' do
      attributes = {
        'FullName' => 'Stark, Tony and Pepper Potts',
        'Phone' => '(555) 999-9999'
      }
      row = xml.tables['Contact'].last
      row['FullName'] = attributes['FullName']
      row['Phone'] = attributes['Phone']

      expect(xml.find('Contact', attributes)).to eq row
    end

    it 'does not raise if table does not exist' do
      expect(xml.find('SuperHero', '1')).to eq(nil)
    end
  end
end
