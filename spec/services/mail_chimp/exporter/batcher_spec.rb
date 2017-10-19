require 'rails_helper'

RSpec.describe MailChimp::Exporter::Batcher do
  let(:mail_chimp_account) { build(:mail_chimp_account) }
  let(:account_list) { mail_chimp_account.account_list }

  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:list_id) { 'list_one' }

  subject { described_class.new(mail_chimp_account, mock_gibbon_wrapper, list_id) }

  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:mock_gibbon_list_object) { double(:mock_gibbon_list_object) }
  let(:mock_gibbon_batches) { double(:mock_gibbon_batches) }
  let(:mock_interest_categories) { double(:mock_interest_categories) }
  let(:mock_interests) { double(:mock_interests) }

  let(:complete_batch_body) do
    { body: { operations: operations_body } }
  end

  before do
    allow(mock_gibbon_wrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list_object)
    allow(mock_gibbon_wrapper).to receive(:batches).and_return(mock_gibbon_batches)
    allow(mock_gibbon_list_object).to receive(:lists).and_return('list_one')
    allow(mock_gibbon_list_object).to receive(:interest_categories).and_return(mock_interest_categories)
    allow(mock_interest_categories).to receive(:interests).and_return(mock_interests)
    allow(mock_interests).to receive(:retrieve).and_return(
      'interests' => [
        {
          'name' => 'Status or Tag',
          'id' => 'random'
        }
      ]
    )
  end

  context '#subscribe_contacts' do
    let(:first_email) { 'email@gmail.com' }
    let!(:contact) { create(:contact, account_list: account_list, people: [person, person_opted_out]) }

    let(:person) do
      create(:person, primary_email_address: build(:email_address, email: first_email))
    end

    let(:person_opted_out) do
      create(:person, optout_enewsletter: true, primary_email_address: build(:email_address))
    end

    let(:operations_body) do
      [
        {
          method: 'PUT',
          path: '/lists/list_one/members/1919bfc4fa95c7f6b231e583da677a17',
          body: {
            status: 'subscribed',
            email_address: 'email@gmail.com',
            merge_fields: {
              EMAIL: 'email@gmail.com',
              FNAME: person.first_name,
              LNAME: person.last_name,
              GREETING: contact.greeting
            },
            language: 'en',
            interests: {
              random: false
            }
          }.to_json
        }
      ]
    end

    before do
      # This block of code ensures that MC batches method will trigger each
      # of the 3 types of errors that are handled by the import.

      times_called = 0

      allow(mock_gibbon_batches).to receive(:create) do
        times_called += 1

        case times_called
        when 1
          raise Gibbon::MailChimpError, 'You have more than 500 pending batches.'
        when 2
          raise Gibbon::MailChimpError, 'nested too deeply'
        when 3
          raise Gibbon::MailChimpError, '<H1>Bad Request</H1>'
        end
      end
    end

    it 'subscribes the contacts and creates the mail_chimp_members handling all 3 MC API intermittent errors' do
      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body).at_least(:once)

      expect do
        subject.subscribe_contacts([contact])
      end.to change { mail_chimp_account.mail_chimp_members.reload.count }.by(1)
    end
  end

  context '#unsubscribe_contacts' do
    let!(:mail_chimp_member) do
      create(:mail_chimp_member,
             mail_chimp_account: mail_chimp_account,
             email: 'email@gmail.com',
             list_id: 'list_one')
    end

    let!(:second_mail_chimp_member) do
      create(:mail_chimp_member,
             mail_chimp_account: mail_chimp_account,
             list_id: 'list_one')
    end

    let(:operations_body) do
      [
        {
          method: 'PATCH',
          path: '/lists/list_one/members/1919bfc4fa95c7f6b231e583da677a17',
          body: { status: 'unsubscribed' }.to_json
        }
      ]
    end

    it 'unsubscribes the members based on the emails provided' do
      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body)

      subject.unsubscribe_members([mail_chimp_member.email])
    end
  end
end
