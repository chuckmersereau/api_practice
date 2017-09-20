require 'rails_helper'

describe TntImport::ContactsImport do
  let(:user) { create(:user) }
  let(:import) { create(:tnt_import, override: true, user: user) }
  let(:tnt_import) { TntImport.new(import) }

  it 'does not include the contacts in the return hash if they were not saved' do
    importer = TntImport::ContactsImport.new(import, create(:designation_profile), tnt_import.xml)
    expect(importer).to receive(:import_contact).and_return(double(id: nil)).twice
    expect(importer.import_contacts).to eq({})
  end
end
