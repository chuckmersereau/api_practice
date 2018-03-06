require 'rails_helper'

describe MailChimpAccount do
  let(:api_prefix) { 'https://us4.api.mailchimp.com/3.0' }
  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:mail_chimp_account) { create(:mail_chimp_account, api_key: 'fake-us4', primary_list_id: primary_list_id, account_list: account_list) }
  let(:account_list) { create(:account_list) }
  let(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:newsletter_contacts) do
    contacts = []
    2.times do
      contacts << create(
        :contact,
        people: [create(:person, email_addresses: [build(:email_address)])],
        account_list: account_list_with_mailchimp,
        send_newsletter: 'Email'
      )
    end
    contacts
  end
  let(:non_newsletter_contacts) do
    [create(
      :contact,
      people: [create(:person, email_addresses: [build(:email_address)])],
      account_list: account_list_with_mailchimp,
      send_newsletter: 'Physical'
    )]
  end

  it 'validates the format of an api key' do
    expect(MailChimpAccount.new(account_list_id: account_list.id, api_key: 'DEFAULT__{8D2385FE-5B3A-4770-A399-1AF1A6436A00}')).not_to be_valid
    expect(MailChimpAccount.new(account_list_id: account_list.id, api_key: 'jk234lkwjntlkj3n5lk3j3kj-us4')).to be_valid
  end

  it 'deactivates the account if the api key is invalid' do
    error = {
      title: 'API Key Invalid', status: 401,
      detail: "Your API key may be invalid, or you've attempted to access the wrong datacenter."
    }
    stub_request(:get, "#{api_prefix}/lists").to_return(status: 401, body: error.to_json)
    mail_chimp_account.active = true

    mail_chimp_account.validate_key

    expect(mail_chimp_account.active).to be false
    expect(mail_chimp_account.validation_error).to match(/Your API key may be invalid/)
  end

  describe '#appeal_open_rate' do
    let(:mock_gibbon) { double(:mock_gibbon) }
    let(:mock_gibbon_list) { double(:mock_gibbon_list) }

    it 'returns the open rate given by the mail chimp api' do
      expect_any_instance_of(MailChimp::GibbonWrapper).to receive(:gibbon).and_return(mock_gibbon)
      expect(mock_gibbon).to receive(:lists).and_return(mock_gibbon_list)
      expect(mock_gibbon_list).to receive(:retrieve).and_return(
        {
          lists: [
            {
              id: primary_list_id_2,
              name: 'Appeal List',
              stats: {
                open_rate: 20
              }
            }
          ]
        }.with_indifferent_access
      )
      MailChimpAppealList.create(mail_chimp_account: mail_chimp_account, appeal_id: appeal.id, appeal_list_id: primary_list_id_2)
      mail_chimp_account.update!(active: true)

      expect(mail_chimp_account.appeal_open_rate).to eq(20)
    end
  end

  context 'email generating methods' do
    let(:contacts) { newsletter_contacts + non_newsletter_contacts }
    let(:contact_ids) { contacts.map(&:id) }

    before do
      newsletter_contacts
      non_newsletter_contacts
    end

    describe '#relevant_contacts' do
      context 'contact_ids set' do
        it 'returns newsletter configured contacts' do
          expect(mail_chimp_account.relevant_contacts(contact_ids)).to match_array(newsletter_contacts)
        end
        context 'force_sync is true' do
          it 'return all contacts' do
            expect(mail_chimp_account.relevant_contacts(contact_ids, true)).to match_array(contacts)
          end
        end
      end
      it 'returns newsletter configured contacts' do
        expect(mail_chimp_account.relevant_contacts).to match_array(newsletter_contacts)
      end
    end
  end
end
