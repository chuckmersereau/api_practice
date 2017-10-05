require 'rails_helper'

describe MailChimp::Exporter do
  let(:list_id) { 'list_one_id' }

  let(:mail_chimp_account) { create(:mail_chimp_account, active: true) }
  let(:account_list) { mail_chimp_account.account_list }

  subject { described_class.new(mail_chimp_account, list_id) }

  let(:mock_connection_handler) { double(:mock_connection_handler) }
  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }

  let(:mock_batcher) { double(:mock_batcher) }
  let(:mock_group_adder) { double(:mock_group_adder) }

  let(:mock_interest_ids_cacher) { double(:mock_interest_ids_cacher) }
  let(:mock_merge_field_adder) { double(:mock_merge_field_adder) }

  let(:mock_gibbon_list) { double(:mock_gibbon_list) }

  let(:contacts) do
    create_list(:contact, 3,
                account_list: account_list,
                tag_list: 'tag',
                people: [build(:person, primary_email_address: build(:email_address))])
  end

  let(:appeal) { create(:appeal, account_list: account_list) }

  context '#export_contacts' do
    it 'uses the connection handler and export_contacts! is called' do
      expect(MailChimp::ConnectionHandler).to receive(:new).and_return(mock_connection_handler)
      expect(mock_connection_handler).to receive(:call_mail_chimp).with(subject, :export_contacts!, nil)

      subject.export_contacts
    end
  end

  context '#export_contacts!' do
    let!(:mail_chimp_member) { create(:mail_chimp_member, mail_chimp_account: mail_chimp_account, list_id: list_id) }

    before do
      allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:list_emails).and_return(['email@gmail.com'])
      allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list)
      allow_any_instance_of(MailChimpAccount).to receive(:relevant_contacts).and_return(Contact.limit(2))
      allow_any_instance_of(MailChimpAccount).to receive(:active_contacts_with_emails).and_return(Contact.limit(1))

      allow(described_class::GroupAdder).to receive(:new).and_return(mock_group_adder)
      allow(described_class::Batcher).to receive(:new).and_return(mock_batcher)
      allow(described_class::MergeFieldAdder).to receive(:new).and_return(mock_merge_field_adder)
    end

    it 'calls GroupAdder, MergeFieldAdder and Batcher instances with correct arguments' do
      expect(mock_group_adder).to receive(:add_status_groups).with(['Partner - Financial', 'Partner - Pray'])
      expect(mock_group_adder).to receive(:add_tags_groups).with(['tag'])

      expect(mock_merge_field_adder).to receive(:add_merge_field).with('GREETING')

      expect(mock_batcher).to receive(:subscribe_contacts).with(contacts)

      expect(mock_batcher).to receive(:unsubscribe_members).with([mail_chimp_member.email])

      subject.export_contacts!(contacts.map(&:id))
    end
  end
end
