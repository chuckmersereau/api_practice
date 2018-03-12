require 'rails_helper'

RSpec.describe MailChimp::Syncer do
  subject { described_class.new(mail_chimp_account) }

  let(:list_id) { 'list_one' }
  let(:webhook_token) { 'webhook_token' }

  let(:mail_chimp_account) { create(:mail_chimp_account, active: true, primary_list_id: list_id) }

  let(:mock_importer) { double(:mock_importer) }
  let(:mock_exporter) { double(:mock_exporter) }
  let(:mock_connection_handler) { double(:mock_connection_handler) }

  let(:mock_list) { double(:mock_list) }
  let(:mock_request) { double(:mock_request) }
  let(:mock_wrapper) { double(:mock_wrapper) }
  let(:mock_webhooks) { double(:mock_webhooks) }

  context '#sync_with_primary_list' do
    context 'connection_handler, importer and exporter' do
      let!(:mail_chimp_member_one) { create(:mail_chimp_member, mail_chimp_account: mail_chimp_account, list_id: list_id) }
      let!(:mail_chimp_member_two) { create(:mail_chimp_member, mail_chimp_account: mail_chimp_account, list_id: 'random_list') }
      let!(:mail_chimp_member_three) do
        create(:mail_chimp_member, mail_chimp_account: mail_chimp_account,
                                   list_id: list_id,
                                   email: 'ironman@marvel.com')
      end
      let!(:mail_chimp_member_four) do
        create(:mail_chimp_member, mail_chimp_account: mail_chimp_account,
                                   list_id: list_id,
                                   email: 'antman@marvel.com')
      end

      before do
        allow(Gibbon::Request).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:lists).with(list_id).and_return(mock_list)
        allow(mock_list).to receive(:webhooks).and_return(mock_webhooks)
        allow(mock_webhooks).to receive(:retrieve)
        allow(mock_webhooks).to receive(:create)
        allow(MailChimp::GibbonWrapper).to receive(:new).and_return(mock_wrapper)
        mock_member_info_one = {
          'status' => 'unsubscribed',
          'email_address' => mail_chimp_member_one.email
        }
        mock_member_info_three = {
          'status' => 'subscribed',
          'email_address' => mail_chimp_member_three.email
        }
        allow(mock_wrapper).to receive(:list_members).and_return([mock_member_info_one, mock_member_info_three])
      end

      it 'it uses the connection handler' do
        expect(MailChimp::ConnectionHandler).to receive(:new).and_return(mock_connection_handler)
        expect(mock_connection_handler).to receive(:call_mail_chimp).with(subject, :two_way_sync_with_primary_list!)

        subject.two_way_sync_with_primary_list
      end

      it 'deletes existing members' do
        subject.two_way_sync_with_primary_list

        expect(MailChimpMember.exists?(mail_chimp_member_one.id)).to be false

        # doesn't delete if not on list_id
        expect(MailChimpMember.exists?(mail_chimp_member_two.id)).to be true

        # doesn't delete if still subscribed
        expect(MailChimpMember.exists?(mail_chimp_member_three.id)).to be true

        # deletes if not in member info list
        expect(MailChimpMember.exists?(mail_chimp_member_four.id)).to be false
      end

      # it 'calls the importer and exporter classes' do
      #   expect(MailChimp::Importer).to receive(:new).and_return(mock_importer)
      #   expect(mock_importer).to receive(:import_all_members)
      #
      #   expect(MailChimp::ExportContactsWorker).to receive(:perform_async).with(mail_chimp_account.id, list_id, nil)
      #
      #   expect do
      #     subject.two_way_sync_with_primary_list!
      #   end.to change { mail_chimp_account.mail_chimp_members.reload.count }.from(2).to(1)
      # end
    end

    context 'webhooks' do
      before do
        allow_any_instance_of(MailChimp::Importer).to receive(:import_all_members)
        allow_any_instance_of(MailChimp::Exporter).to receive(:export_contacts)
        allow_any_instance_of(MailChimp::Syncer).to receive(:delete_mail_chimp_members)
        allow(Rails.env).to receive(:staging?).and_return(true)
      end

      it 'sets up webhooks when it was never done before for the mail_chimp_account webhook_token' do
        mail_chimp_account.webhook_token = 'random_token'
        expect_webhooks_instantiation_and_retrieve_call

        expect(mock_webhooks).to receive(:create)

        subject.two_way_sync_with_primary_list!
      end

      it 'does not set up webhooks when it was done before' do
        mail_chimp_account.webhook_token = webhook_token
        expect_webhooks_instantiation_and_retrieve_call
        expect(mock_webhooks).to_not receive(:create)

        subject.two_way_sync_with_primary_list!
      end

      def expect_webhooks_instantiation_and_retrieve_call
        allow(Gibbon::Request).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:lists).with(list_id).and_return(mock_list)
        allow(mock_list).to receive(:webhooks).and_return(mock_webhooks)
        expect(mock_webhooks).to receive(:retrieve).and_return(
          'webhooks' => [
            {
              'url' => "https://api.mpdx.test/mail_chimp_webhook/#{webhook_token}"
            }
          ]
        )
      end
    end
  end
end
