require 'rails_helper'

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
    before do
      @contact = Contact.new(notes: 'Another note')
    end

    it 'updates notes correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq("Principal\nHas run into issues with Campus Crusade. \n \nChildren: Mark and Robert")
    end

    it 'doesnt add the children and tnt notes twice to notes' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq("Principal\nHas run into issues with Campus Crusade. \n \nChildren: Mark and Robert")
    end

    it 'updates newsletter preferences correctly' do
      import.send(:update_contact, @contact, contact_rows.first)
      expect(@contact.send_newsletter).to eq('Physical')
    end

    it 'sets the address region' do
      import.send(:update_contact, @contact, contact_rows.first)
      expect(@contact.addresses.first.region).to eq('State College')
    end
  end

  it 'does not cause an error and increases contact count for case with first email not preferred' do
    row = load_yaml_row(:tnt_row_multi_email)
    expect { import.send(:import_contact, row) }.to change(Contact, :count).by(1)
  end

  it 'does not cause an error if phone is invalid and person has email' do
    account_list = create(:account_list)
    tnt_import = double(user: double, account_list: account_list,
                        override?: true)
    import = TntImport::ContactImport.new(tnt_import, [], [])
    row = load_yaml_row(:bad_phone_valid_email_row)

    expect do
      import.import_contact(row)
    end.to change(Contact, :count).by(1)

    contact = Contact.last
    expect(contact.people.count).to eq 1
    person = contact.people.first
    expect(person.phone_numbers.count).to eq 1
    expect(person.phone_numbers.first.number).to eq '(UNLISTED) call office'
    expect(person.email_addresses.count).to eq 1
    expect(person.email_addresses.first.email).to eq 'ron@t.co'
  end

  def load_yaml_row(filename)
    YAML.load(File.new(Rails.root.join("spec/fixtures/tnt/#{filename}.yaml")).read)
  end
end