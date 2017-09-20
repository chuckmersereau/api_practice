require 'rails_helper'

describe TntImport::ReferralsImport do
  let(:user) { create(:user) }
  let(:import) { create(:tnt_import, override: true, user: user) }
  let(:tnt_import) { TntImport.new(import) }

  it 'handles a nil contact id without crashing' do
    contact_rows = tnt_import.xml.tables['Contact']
    contact_ids_by_tnt_contact_id = contact_rows.each_with_object({}) { |row, hash| hash[row['id']] = nil }
    expect { TntImport::ReferralsImport.new(contact_ids_by_tnt_contact_id, contact_rows).import }.to_not raise_error
  end
end
