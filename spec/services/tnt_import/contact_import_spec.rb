require 'rails_helper'

describe TntImport::ContactImport do
  include TntImportHelpers

  def load_yaml_row(filename)
    YAML.load(File.new(Rails.root.join("spec/fixtures/tnt/#{filename}.yaml")).read)
  end

  def shared_attributes_options
    @shared_attributes_options ||= []
  end

  let(:file) { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export.xml')) }
  let(:tnt_import) { create(:tnt_import, override: true, file: file) }
  let(:xml) { TntImport::XmlReader.new(tnt_import).parsed_xml }
  let(:contact_rows) { xml.tables['Contact'] }
  let(:tags) { %w(tag1 tag2) }
  let(:import) do
    donor_accounts = []
    TntImport::ContactImport.new(tnt_import, tags, donor_accounts, xml.tables['NewsletterLang'])
  end

  before { stub_smarty_streets }

  describe '#update_contact' do
    let(:contact) { create(:contact, notes: 'Another note') }

    let(:expected_note) do
      "Principal\nHas run into issues with Campus Crusade. \n \nChildren: Mark and Robert " \
      "\n \nUser Status: Custom user status \n \nCategories: Custom category one, Category two " \
      "\n \nInterests: Working Out, Bowling, Solving Crimes \n \nSpouse Interests: HelensInterests " \
      "\n \nNickname: BobsNickname \n \nSpouse Nickname: Helen's Nickname"
    end

    it 'updates notes correctly' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq(expected_note)
    end

    it 'doesnt add the children and tnt notes twice to notes' do
      contact = Contact.new
      import.send(:update_contact, contact, contact_rows.first)
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.notes).to eq(expected_note)
    end

    it 'updates newsletter preferences correctly' do
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.send_newsletter).to eq('Physical')
    end

    it 'sets the address region' do
      import.send(:update_contact, contact, contact_rows.first)
      expect(contact.addresses.first.region).to eq('State College')
    end

    it 'creates a duplicate address if original is not from TntImport' do
      import.send(:update_contact, contact, contact_rows.first)
      contact.addresses.first.update!(source: 'Something Else')

      import.send(:update_contact, contact, contact_rows.first)

      expect(contact.addresses.count).to eq 2
      expect(contact.addresses.first.source).to eq 'Something Else'
      expect(contact.addresses.second.source).to eq 'TntImport'
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

    it 'sets is_organization' do
      row = tnt_import_parsed_xml_sample_contact_row
      expect(import.import_contact(row).is_organization).to eq false
      row['IsOrganization'] = 'true'
      expect(import.import_contact(row).is_organization).to eq true
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

    context 'has newsletter language field' do
      let(:file) { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_broad.xml')) }

      it 'adds supported language to contact field' do
        # language in xml is French
        contact = import.import_contact(tnt_import_parsed_xml_sample_contact_row)

        expect(contact.locale).to eq 'fr'
      end

      it 'adds unsupported language to the contact notes' do
        # language spoken in Wakanda
        xml.find('NewsletterLang', '557339175')['Description'] = 'Xhosa'

        tags_list = import.import_contact(tnt_import_parsed_xml_sample_contact_row).tag_list

        expect(tags_list).to include('xhosa')
      end
    end

    context 'importing send_newsletter' do
      it 'supports overriding' do
        row = tnt_import_parsed_xml_sample_contact_row

        tnt_import.override = false
        import = TntImport::ContactImport.new(tnt_import, tags, [], [])

        expect(import.import_contact(row).send_newsletter).to eq('Both')

        row['SendNewsletter'] = 'false'
        expect(import.import_contact(row).send_newsletter).to eq('Both')

        tnt_import.override = true
        import = TntImport::ContactImport.new(tnt_import, tags, [], [])
        expect(import.import_contact(row).send_newsletter).to eq('None')
      end
    end
  end

  it 'does not cause an error and increases contact count for case with first email not preferred' do
    row = load_yaml_row(:tnt_row_multi_email)
    expect { import.send(:import_contact, row) }.to change(Contact, :count).by(1)
  end

  it 'does not cause an error if phone is invalid and person has email' do
    account_list = create(:account_list)
    tnt_import = double(user: build(:user), account_list: account_list,
                        override?: true)
    import = TntImport::ContactImport.new(tnt_import, [], [], [])
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

  it 'imports given tags' do
    row = contact_rows.first
    expect(import.import_contact(row).tag_list).to eq(tags)
  end

  describe 'importing Contact attributes' do
    let(:shared_attributes_options) do
      [
        {
          attribute_name: :name, first_value: 'Bob', expected_first_value: 'Bob',
          second_value: 'Joe', tnt_row_key: 'FileAs', required: true
        },
        {
          attribute_name: :full_name, first_value: 'Bob', expected_first_value: 'Bob',
          second_value: 'Joe', tnt_row_key: 'FullName'
        },
        {
          attribute_name: :greeting, first_value: 'Bob', expected_first_value: 'Bob',
          second_value: 'Joe', tnt_row_key: 'Greeting'
        },
        {
          attribute_name: :envelope_greeting, first_value: 'Address One', expected_first_value: 'Address One',
          second_value: 'Address Two', tnt_row_key: 'MailingAddressBlock'
        },
        {
          attribute_name: :website, first_value: 'www.mpdx.org', expected_first_value: 'www.mpdx.org',
          second_value: 'www.cru.org', tnt_row_key: 'WebPage'
        },
        {
          attribute_name: :church_name, first_value: 'Cool Church', expected_first_value: 'Cool Church',
          second_value: 'Brisk Basilica', tnt_row_key: 'ChurchName'
        },
        {
          attribute_name: :direct_deposit, first_value: 'true', expected_first_value: true,
          second_value: 'false', tnt_row_key: 'DirectDeposit'
        },
        {
          attribute_name: :magazine, first_value: 'true', expected_first_value: true,
          second_value: 'false', tnt_row_key: 'Magazine'
        },
        {
          attribute_name: :tnt_id, first_value: 1, expected_first_value: 1,
          second_value: 2, tnt_row_key: 'id', uses_override: false
        },
        {
          attribute_name: :is_organization, first_value: 'true', expected_first_value: true,
          second_value: 'false', tnt_row_key: 'IsOrganization'
        },
        {
          attribute_name: :pledge_amount, first_value: 1234.56, expected_first_value: 1234.56.to_d,
          second_value: 7890, tnt_row_key: 'PledgeAmount'
        },
        {
          attribute_name: :pledge_frequency, first_value: 1, expected_first_value: 1.0,
          second_value: 2, tnt_row_key: 'PledgeFrequencyID'
        },
        {
          attribute_name: :pledge_received, first_value: 'true', expected_first_value: true,
          second_value: 'false', tnt_row_key: 'PledgeReceived'
        },
        {
          attribute_name: :status, first_value: 10, expected_first_value: 'Never Contacted',
          second_value: 20, tnt_row_key: 'MPDPhaseID'
        },
        {
          attribute_name: :likely_to_give, first_value: 1, expected_first_value: 'Least Likely',
          second_value: 2, tnt_row_key: 'LikelyToGiveID'
        },
        {
          attribute_name: :no_appeals, first_value: 'true', expected_first_value: true,
          second_value: 'false', tnt_row_key: 'NeverAsk'
        },
        {
          attribute_name: :estimated_annual_pledge_amount, first_value: 1234.56, expected_first_value: 1234.56.to_d,
          second_value: 7890, tnt_row_key: 'EstimatedAnnualCapacity'
        },
        {
          attribute_name: :next_ask_amount, first_value: 1234.56, expected_first_value: 1234.56.to_d,
          second_value: 7890, tnt_row_key: 'NextAskAmount'
        }
      ]
    end
    let(:override_options) { shared_attributes_options.reject { |options| options[:uses_override] == false } }
    let(:row) { contact_rows.first }

    before do
      shared_attributes_options.each do |options|
        raise 'Values should be different!' if options[:first_value] == options[:second_value]
      end
    end

    def values_for(object, attribute_names)
      attribute_names.each_with_object({}) do |attribute_name, hash|
        hash[attribute_name] = object.send(attribute_name).to_s
      end
    end

    def expected_values(options_hash, value_key)
      options_hash.each_with_object({}) do |o, hash|
        hash[o[:attribute_name]] = o[value_key].to_s
      end
    end

    def run_first_import(override = true)
      row = contact_rows.first
      shared_attributes_options.each { |options| row[options[:tnt_row_key]] = options[:first_value] }
      tnt_import.override = override

      import.import_contact(row)
    end

    it 'imports attribute' do
      run_first_import

      attributes = values_for(Contact.last, shared_attributes_options.collect { |o| o[:attribute_name] })
      expect(attributes).to eq expected_values(shared_attributes_options, :expected_first_value)
    end

    it 'imports attribute when nil' do
      tnt_import.override = true
      shared_attributes_options.reject { |o| o[:required] }.each do |options|
        row.delete options[:tnt_row_key]
      end

      expect { import.import_contact(row) }.to change { Contact.count }
    end

    it "doesn't import if missing required values" do
      tnt_import.override = true

      shared_attributes_options.select { |o| o[:required] }.each do |options|
        Contact.destroy_all
        row.delete options[:tnt_row_key]
        expect { import.import_contact(row) }.to_not change { Contact.count }
      end
    end

    it 'overrides if override is true' do
      run_first_import

      contact = Contact.last
      attributes = values_for(contact, override_options.collect { |o| o[:attribute_name] })
      expect(attributes).to eq expected_values(override_options, :expected_first_value)

      # fill row with import values
      override_options.each { |options| row[options[:tnt_row_key]] = options[:second_value] }

      expect { import.import_contact(row) }.to_not change { Contact.count }

      # expect all values to have changed
      attributes = values_for(contact.reload, override_options.collect { |o| o[:attribute_name] })
      old_values = expected_values(override_options, :expected_first_value)
      diff = (attributes.to_a - old_values.to_a).to_h
      expect(diff.keys).to eq override_options.collect { |o| o[:attribute_name] }
    end

    it 'does not override if override is false' do
      run_first_import(false)

      contact = Contact.last
      # expect values to be set on first run even though override = false
      attributes = values_for(contact, override_options.collect { |o| o[:attribute_name] })
      expect(attributes).to eq expected_values(override_options, :expected_first_value)

      # fill row with import values
      override_options.each { |options| row[options[:tnt_row_key]] = options[:second_value] }

      expect { import.import_contact(row) }.to_not change { Contact.count }

      # expect all values to still expect first value
      attributes = values_for(contact.reload, override_options.collect { |o| o[:attribute_name] })
      expect(attributes).to eq expected_values(override_options, :expected_first_value)
    end
  end
end
