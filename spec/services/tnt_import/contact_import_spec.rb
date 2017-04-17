require 'rails_helper'

describe TntImport::ContactImport do
  include TntImportHelpers

  let(:file) { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export.xml')) }
  let(:tnt_import) { create(:tnt_import, override: true, file: file) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:contact_rows) { xml.tables['Contact'] }
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

    it 'sets the greeting' do
      greeting = import.import_contact(tnt_import_parsed_xml_sample_contact_row).greeting
      expect(greeting).to eq 'Parr Custom Greeting'
    end

    it 'sets the envelope_greeting' do
      row = tnt_import_parsed_xml_sample_contact_row
      envelope_greeting = import.import_contact(row).envelope_greeting
      expect(envelope_greeting).to eq 'Parr Custom Fullname'
      row['MailingAddressBlock'] = ''
      row['FullName'] = 'My Special Full Name'
      envelope_greeting = import.import_contact(row).envelope_greeting
      expect(envelope_greeting).to eq 'My Special Full Name'
    end

    context 'has social web fields' do
      let(:file) { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

      it 'adds unsupported social fields to the contact notes' do
        notes = import.import_contact(tnt_import_parsed_xml_sample_contact_row).notes
        expect(notes).to include('Other Social: bob-other-social')
        expect(notes).to include('Spouse Other Social: @helenothersocial')
        expect(notes).to include('Voice/Skype: bobparrskype')
        expect(notes).to include('Spouse Voice/Skype: HelenParrSkype')
        expect(notes).to include('IM Address: bobsIMaddress')
        expect(notes).to include('Spouse IM Address: helenIMaddress')
      end
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

  it 'ignores negative PledgeFrequencyID' do
    row = contact_rows.first
    row['PledgeFrequencyID'] = -11
    tnt_import.override = true
    import.import_contact(row)
    expect(Contact.last.pledge_frequency).to eq nil
  end

  it 'ignores a zero PledgeFrequencyID' do
    row = contact_rows.first
    row['PledgeFrequencyID'] = 0
    tnt_import.override = true
    import.import_contact(row)
    expect(Contact.last.pledge_frequency).to eq nil
  end

  def load_yaml_row(filename)
    YAML.load(File.new(Rails.root.join("spec/fixtures/tnt/#{filename}.yaml")).read)
  end
end
