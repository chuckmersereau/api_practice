require 'rails_helper'

describe TntImport::Xml do
  let(:tnt_import) { create(:tnt_import, override: true) }
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
                                       TaskType)
    end
  end

  describe '#version' do
    it 'returns parsed version as a float' do
      expect(xml.version).to be_a Float
      expect(xml.version).to eq 3.0
    end
  end
end
