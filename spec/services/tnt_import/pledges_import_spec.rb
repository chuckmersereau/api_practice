require 'rails_helper'

describe TntImport::PledgesImport do
  let(:import) { create(:tnt_import_campaigns_and_promises, override: true) }
  let(:tnt_import) { TntImport.new(import) }
  let(:xml) { tnt_import.xml }
  let(:account_list) { import.account_list }
  let(:pledges_import) { TntImport::PledgesImport.new(account_list, import, xml) }

  before do
    Array.wrap(xml.tables['Promise']).each do |row|
      account_list.contacts.create!(name: 'Bob', tnt_id: row['ContactID'])
    end
  end

  describe '#import' do
    it 'creates expected number of pledge records' do
      expect { pledges_import.import }.to change { Pledge.count }.from(0).to(13)
      pledge = Pledge.order(:created_at).last
      expect(pledge.amount).to eq(75)
      expect(pledge.amount_currency).to eq('USD')
      expect(pledge.expected_date).to eq(Date.parse('2017-06-10'))
      expect(pledge.account_list_id).to eq(account_list.id)
      expect(pledge.contact_id).to be_present
    end

    it 'does not import the same pledges a second time' do
      expect { pledges_import.import }.to change { Pledge.count }.from(0).to(13)
      expect { pledges_import.import }.to_not change { Pledge.count }.from(13)
    end
  end
end
