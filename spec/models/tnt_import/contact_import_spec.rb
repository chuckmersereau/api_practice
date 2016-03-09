require 'spec_helper'

describe TntImport::ContactImport do
  let(:tnt_import) { create(:tnt_import, override: true) }
  let(:xml) do
    TntImport::XmlReader.new(tnt_import).parsed_xml
  end
  let(:contact_rows) { Array.wrap(xml['Contact']['row']) }
  let(:import) do
    donor_accounts = []
    tags = []
    TntImport::ContactImport.new(tnt_import, tags, donor_accounts)
  end

  before { stub_smarty_streets }

  context '#update_contact' do
    it 'updates notes correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq("Principal\nHas run into issues with Campus Crusade in the past...  Was told couldn't be involved because hadn't been baptized as an adult.")
    end

    it 'updates newsletter preferences correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.send_newsletter).to eq('Physical')
    end

    it 'sets the address region' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.addresses.first.region).to eq('State College')
    end
  end

  it 'does not cause an error and increases contact count for case with first email not preferred' do
    row = YAML.load(File.new(Rails.root.join('spec/fixtures/tnt/tnt_row_multi_email.yaml')).read)
    expect { import.send(:import_contact, row) }.to change(Contact, :count).by(1)
  end
end
