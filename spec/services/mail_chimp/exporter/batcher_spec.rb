require 'rails_helper'

RSpec.describe MailChimp::Exporter::Batcher do
  let(:mail_chimp_account) { build(:mail_chimp_account) }
  let(:account_list) { mail_chimp_account.account_list }

  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:list_id) { 'list_one' }
  let(:email_hash) { '1919bfc4fa95c7f6b231e583da677a17' }

  subject { described_class.new(mail_chimp_account, mock_gibbon_wrapper, list_id) }

  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }
  let(:mock_gibbon_list_object) { double(:mock_gibbon_list_object) }
  let(:mock_gibbon_batches) { double(:mock_gibbon_batches) }
  let(:mock_interest_categories) { double(:mock_interest_categories) }
  let(:mock_interests) { double(:mock_interests) }
  let(:mock_batch_response) { { 'id' => 'a1b2c3', '_links' => [] } }

  let(:complete_batch_body) do
    { body: { operations: operations_body } }
  end

  before do
    allow(mock_gibbon_wrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list_object)
    allow(mock_gibbon_wrapper).to receive(:batches).and_return(mock_gibbon_batches)
    allow(mock_gibbon_list_object).to receive(:lists).and_return(list_id)
    allow(mock_gibbon_list_object).to receive(:interest_categories).and_return(mock_interest_categories)
    allow(mock_interest_categories).to receive(:interests).and_return(mock_interests)
    allow(mock_interests).to receive(:retrieve).and_return(
      'interests' => [
        {
          'name' => 'status or tag',
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
          path: "/lists/#{list_id}/members/#{email_hash}",
          body: person_operation_body.to_json
        }
      ]
    end

    let(:person_operation_body) do
      {
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
      }
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
        else
          mock_batch_response
        end
      end
    end

    it 'subscribes the contacts and creates the mail_chimp_members handling all 3 MC API intermittent errors' do
      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body).exactly(4)

      expect do
        subject.subscribe_contacts([contact])
      end.to change { mail_chimp_account.mail_chimp_members(true).count }.by(1)
    end

    it 'adds tag interests' do
      contact.tag_list.add('status or tag')

      subject.subscribe_contacts([contact])

      expect(mail_chimp_account.mail_chimp_members(true).last.tags.compact).to_not be_empty
    end

    it 'logs request to AudtChangeLog' do
      expect(AuditChangeWorker).to receive(:perform_async)

      subject.subscribe_contacts([contact])
    end

    it 'adds worker to watch batch results' do
      expect do
        subject.subscribe_contacts([contact])
      end.to change(MailChimp::BatchResultsWorker.jobs, :size).by(1)
    end

    it "doesn't send null on last name or greeting" do
      person.update!(last_name: nil)
      contact.update!(greeting: nil)
      person_operation_body[:merge_fields][:LNAME] = ''
      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body).exactly(4)

      subject.subscribe_contacts([contact])
    end
  end

  context '#unsubscribe_contacts' do
    let!(:mail_chimp_member) do
      create(:mail_chimp_member,
             mail_chimp_account: mail_chimp_account,
             email: 'email@gmail.com',
             list_id: list_id)
    end

    let!(:second_mail_chimp_member) do
      create(:mail_chimp_member,
             mail_chimp_account: mail_chimp_account,
             list_id: list_id)
    end

    let(:operations_body) do
      [
        {
          method: 'PATCH',
          path: "/lists/#{list_id}/members/#{email_hash}",
          body: { status: 'unsubscribed' }.to_json
        }
      ]
    end

    it 'unsubscribes the members based on the emails provided' do
      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body).and_return(mock_batch_response)

      subject.unsubscribe_members(mail_chimp_member.email => nil)
    end

    it 'sends provided unsubscribe reason to mailchimp' do
      reason = 'Test Reason'
      operations_body << {
        method: 'POST',
        path: "/lists/#{list_id}/members/#{email_hash}/notes",
        body: { note: "Unsubscribed by MPDX: #{reason}" }.to_json
      }

      expect(mock_gibbon_batches).to receive(:create).with(complete_batch_body).and_return(mock_batch_response)
      subject.unsubscribe_members(mail_chimp_member.email => reason)
    end

    it 'destroys associated mail chimp members' do
      allow(mock_gibbon_batches).to receive(:create).and_return(mock_batch_response)

      expect do
        subject.unsubscribe_members(mail_chimp_member.email => nil)
      end.to change(MailChimpMember, :count).by(-1)
    end
  end
end
