require 'rails_helper'

describe MailChimp::Exporter do
  let(:list_id) { 'list_one_id' }
  let(:mail_chimp_account) do
    create(
      :mail_chimp_account,
      active: true,
      primary_list_id: list_id
    )
  end
  let(:account_list) { mail_chimp_account.account_list }

  subject { described_class.new(mail_chimp_account, list_id) }

  let(:mock_connection_handler) { double(:mock_connection_handler) }
  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }

  let(:mock_batcher) { double(:mock_batcher) }
  let(:mock_group_adder) { double(:mock_group_adder) }

  let(:mock_interest_ids_cacher) { double(:mock_interest_ids_cacher) }
  let(:mock_merge_field_adder) { double(:mock_merge_field_adder) }

  let(:mock_gibbon_list) { double(:mock_gibbon_list) }

  let!(:contacts) do
    (1..3).map do |count|
      create(
        :contact,
        account_list: account_list,
        tag_list: 'tag',
        people: [
          build(:person, primary_email_address: build(:email_address))
        ],
        created_at: count.weeks.from_now
      )
    end
  end

  let(:appeal) { create(:appeal, account_list: account_list) }

  context '#export_contacts' do
    it 'uses the connection handler and export_contacts! is called' do
      expect(MailChimp::ConnectionHandler).to receive(:new).and_return(mock_connection_handler)
      expect(mock_connection_handler).to receive(:call_mail_chimp).with(subject, :export_contacts!, nil, false)

      subject.export_contacts
    end
  end

  context '#export_contacts!' do
    let(:contact) { Contact.order(:created_at).first }
    let!(:mail_chimp_member) do
      create(
        :mail_chimp_member,
        mail_chimp_account: mail_chimp_account,
        list_id: list_id,
        email: contact.people.first.primary_email_address.email
      )
    end
    let(:unsubscribed_email) { contact.people.first.primary_email_address.email }

    before do
      allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:list_emails).and_return(['email@gmail.com'])
      allow_any_instance_of(MailChimp::GibbonWrapper).to receive(:gibbon_list_object).and_return(mock_gibbon_list)
      allow(described_class::InterestAdder).to receive(:new).and_return(mock_group_adder)
      allow(described_class::Batcher).to receive(:new).and_return(mock_batcher)
      allow(described_class::MergeFieldAdder).to receive(:new).and_return(mock_merge_field_adder)
    end

    it 'calls InterestAdder, MergeFieldAdder and Batcher instances with correct arguments' do
      expect(mock_group_adder).to receive(:add_status_interests).with(['Partner - Financial', 'Partner - Pray'])
      expect(mock_group_adder).to receive(:add_tags_interests).with(['tag'])

      expect(mock_merge_field_adder).to receive(:add_merge_field).with('GREETING')

      expect(mock_batcher).to receive(:subscribe_contacts).with(contacts)
      unsubscribe_reason = 'email on contact with newsletter set to None or Physical'
      expect(mock_batcher).to receive(:unsubscribe_members).with(unsubscribed_email => unsubscribe_reason)
      subject.export_contacts!(contacts.map(&:id), true)
    end

    context 'unsubscribe reason' do
      before do
        allow(mock_group_adder).to receive(:add_status_interests).with(['Partner - Financial', 'Partner - Pray'])
        allow(mock_group_adder).to receive(:add_tags_interests).with(['tag'])
        allow(mock_merge_field_adder).to receive(:add_merge_field).with('GREETING')
        allow(mock_batcher).to receive(:subscribe_contacts).with([contact])
      end

      it 'generates reason when send_newsletter is nil' do
        contact.update(send_newsletter: nil)

        unsubscribe_reason = 'email on contact with newsletter set to None or Physical'
        expect(mock_batcher).to receive(:unsubscribe_members).with(unsubscribed_email => unsubscribe_reason)

        subject.export_contacts!([contact.id], false)
      end

      it 'generates reason when person is opted out' do
        contact.people.first.update(optout_enewsletter: true)

        unsubscribe_reason = "email on person marked as 'Opt-out of Email Newsletter'"
        expect(mock_batcher).to receive(:unsubscribe_members).with(unsubscribed_email => unsubscribe_reason)

        subject.export_contacts!([contact.id], false)
      end

      it 'generates reason when email is not primary' do
        old_email = unsubscribed_email
        contact.people.first.email_addresses.create(email: 'test_primary@gmail.com', primary: true)

        unsubscribe_reason = 'email marked as non-primary'
        expect(mock_batcher).to receive(:unsubscribe_members).with(old_email => unsubscribe_reason)

        subject.export_contacts!([contact.id], false)
      end

      it 'generates reason when email is historic' do
        old_email = unsubscribed_email
        contact.people.first.primary_email_address.update(historic: true)

        unsubscribe_reason = 'email marked as historic'
        expect(mock_batcher).to receive(:unsubscribe_members).with(old_email => unsubscribe_reason)

        subject.export_contacts!([contact.id], false)
      end

      it 'generates reason when email no longer on account' do
        old_email = unsubscribed_email
        contact.people.first.primary_email_address.destroy!

        unsubscribe_reason = 'email not in MPDX'
        expect(mock_batcher).to receive(:unsubscribe_members).with(old_email => unsubscribe_reason)

        subject.export_contacts!([contact.id], false)
      end
    end
  end
end
