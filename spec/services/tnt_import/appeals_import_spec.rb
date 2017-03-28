require 'rails_helper'

describe TntImport::AppealsImport do
  let(:import) { create(:tnt_import, override: true) }
  let(:tnt_import) { TntImport.new(import) }
  let(:xml) { tnt_import.xml }

  before { stub_smarty_streets }

  context 'version 3.2 and higher' do
    before { import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

    it 'expects the right xml version' do
      expect(xml.version).to eq 3.2
    end

    it 'imports Appeals' do
      expect { tnt_import.import }.to change { Appeal.count }.from(0).to(2)
      expect(Appeal.first.attributes.except('id', 'created_at', 'updated_at', 'uuid')).to eq('name' => '2017 Increase Campaign',
                                                                                             'account_list_id' => import.account_list_id, 'amount' => nil,
                                                                                             'description' => nil, 'end_date' => nil,
                                                                                             'tnt_id' => 1_510_627_109)
      expect(Appeal.second.attributes.except('id', 'created_at', 'updated_at', 'uuid')).to eq('name' => '2017 Increase Strategy',
                                                                                              'account_list_id' => import.account_list_id, 'amount' => nil,
                                                                                              'description' => nil, 'end_date' => nil,
                                                                                              'tnt_id' => 1_510_627_107)
    end
  end

  context 'version 3.1 and lower' do
    before { import.file = File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_appeals.xml')) }

    it 'expects the right xml version' do
      expect(xml.version).to eq 3.0
    end

    it 'imports Appeals' do
      expect { tnt_import.import }.to change { Appeal.count }.from(0).to(1)
      expect(Appeal.last.attributes.except('id', 'created_at', 'updated_at', 'uuid')).to eq('name' => 'CSU', 'account_list_id' => import.account_list_id,
                                                                                            'amount' => nil, 'description' => nil,
                                                                                            'end_date' => nil, 'tnt_id' => -2_079_150_908)
    end
  end
end
