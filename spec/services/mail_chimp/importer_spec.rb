require 'rails_helper'

describe MailChimp::Importer do
  let(:mail_chimp_account) { create(:mail_chimp_account, active: true) }
  let(:account_list) { mail_chimp_account.account_list }

  subject { described_class.new(mail_chimp_account) }

  let(:mock_connection_handler) { double(:mock_connection_handler) }
  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }

  let(:mock_matcher) { double(:mock_matcher) }
  let(:mock_gibbon_list) { double(:mock_gibbon_list) }

  let(:email) { 'random@email.com' }

  let(:contacts) do
    create_list(
      :contact,
      3,
      account_list: account_list,
      tag_list: 'tag',
      people: [build(:person, primary_email_address: build(:email_address))]
    )
  end

  context '#import_all_members' do
    it 'uses the connection handler and import_all_members! is called' do
      expect(MailChimp::ConnectionHandler).to receive(:new).and_return(mock_connection_handler)
      expect(mock_connection_handler).to receive(:call_mail_chimp).with(subject, :import_all_members!)

      subject.import_all_members
    end
  end

  context '#import_members_by_email' do
    it 'uses the connection handler and import_members_by_email! is called' do
      expect(MailChimp::ConnectionHandler).to receive(:new).and_return(mock_connection_handler)
      expect(mock_connection_handler).to receive(:call_mail_chimp).with(subject, :import_members_by_email!, [email])

      subject.import_members_by_email([email])
    end
  end

  context '#import_all_members & import_members_by_email' do
    let(:mail_chimp_member) { create(:mail_chimp_member, mail_chimp_account: mail_chimp_account) }

    let(:member_infos) do
      [
        {
          'merge_fields' => {
            'FNAME' => 'First Name',
            'LNAME' => 'Last Name',
            'GREETING' => 'Greeting',
            'GROUPINGS' => 'Random Grouping'
          },
          'email_address' => 'email@gmail.com',
          'status' => 'subscribed'
        },
        {
          'merge_fields' => {
            'FNAME' => 'Second First Name',
            'LNAME' => 'Second Last Name',
            'GREETING' => 'Second Greeting',
            'GROUPINGS' => 'Second Random Grouping'
          },
          'email_address' => 'second_email@gmail.com',
          'status' => 'subscribed'
        },
        {
          'merge_fields' => {},
          'email_address' => 'third_email@gmail.com',
          'status' => 'none'
        }
      ]
    end

    let(:formatted_member_infos) do
      [
        {
          email: 'email@gmail.com',
          first_name: 'First Name',
          last_name: 'Last Name',
          greeting: 'Greeting',
          groupings: 'Random Grouping',
          status: 'subscribed'
        },
        {
          email: 'second_email@gmail.com',
          first_name: 'Second First Name',
          last_name: 'Second Last Name',
          greeting: 'Second Greeting',
          groupings: 'Second Random Grouping',
          status: 'subscribed'
        }
      ]
    end

    let(:matching_people_hash) do
      {
        person.id => {
          email: 'email@gmail.com',
          first_name: 'First Name',
          last_name: 'Last Name',
          greeting: 'Greeting',
          groupings: 'Random Grouping',
          status: 'subscribed'
        }
      }.with_indifferent_access
    end

    let!(:person) { create(:person, primary_email_address: build(:email_address, email: 'email@gmail.com')) }
    let!(:contact) { create(:contact, primary_person: person, send_newsletter: 'Physical') }
    let(:new_contact) { Contact.last }

    before do
      allow(MailChimp::GibbonWrapper).to receive(:new).and_return(mock_gibbon_wrapper)
      allow(mock_gibbon_wrapper).to receive(:list_emails).and_return(['email@gmail.com', 'second_email@gmail.com'])
      allow(mock_gibbon_wrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list)
      allow(mock_gibbon_wrapper).to receive(:list_member_info).and_return(member_infos)

      allow(described_class::Matcher).to receive(:new).and_return(mock_matcher)
    end

    context '#import_all_members!' do
      it 'calls Matcher instance with correct arguments and updates/creates the contact/people records' do
        expect(mock_matcher).to receive(:find_matching_people).with(formatted_member_infos).and_return(matching_people_hash)

        expect do
          subject.import_all_members!
        end.to change { Person.count }.by(1)

        expect(new_contact.send_newsletter).to eq('Email')
        expect(new_contact.primary_person.primary_email_address.email).to eq('second_email@gmail.com')
        expect(contact.reload.send_newsletter).to eq('Both')
      end
    end

    context '#import_members_by_email!' do
      it 'calls Matcher instance with correct arguments and updates/creates the contact/people records' do
        expect(mock_matcher).to receive(:find_matching_people).with(formatted_member_infos).and_return(matching_people_hash)

        expect do
          subject.import_members_by_email!(formatted_member_infos.map { |member| member[:email] })
        end.to change { Person.count }.by(1)

        expect(new_contact.send_newsletter).to eq('Email')
        expect(new_contact.primary_person.primary_email_address.email).to eq('second_email@gmail.com')
        expect(contact.reload.send_newsletter).to eq('Both')
      end
    end
  end
end
