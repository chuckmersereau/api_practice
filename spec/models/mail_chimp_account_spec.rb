require 'rails_helper'

describe MailChimpAccount do
  let(:api_prefix) { 'https://apikey:fake-us4@us4.api.mailchimp.com/3.0' }
  let(:primary_list_id) { '1e72b58b72' }
  let(:primary_list_id_2) { '29a77ba541' }
  let(:mail_chimp_account) { create(:mail_chimp_account, api_key: 'fake-us4', primary_list_id: primary_list_id, account_list: account_list) }
  let(:account_list) { create(:account_list) }
  let(:account_list_with_mailchimp) { create(:account_list, mail_chimp_account: mail_chimp_account) }
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:newsletter_contacts) do
    contacts = []
    2.times do
      contacts << create(:contact, people: [create(:person, email_addresses: [build(:email_address)])], account_list: account_list_with_mailchimp, send_newsletter: 'Email')
    end
    contacts
  end
  let(:non_newsletter_contact) { create(:contact, people: [create(:person, email_addresses: [build(:email_address)])], account_list: account_list_with_mailchimp, send_newsletter: 'Physical') }

  it 'validates the format of an api key' do
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'DEFAULT__{8D2385FE-5B3A-4770-A399-1AF1A6436A00}')).not_to be_valid
    expect(MailChimpAccount.new(account_list_id: 1, api_key: 'jk234lkwjntlkj3n5lk3j3kj-us4')).to be_valid
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

  context '#appeal_open_rate' do
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
      expect(mail_chimp_account.appeal_open_rate).to eq(20)
    end
  end

  context 'email generating methods' do
    before do
      newsletter_contacts
      non_newsletter_contact
    end

    context '#relevant_emails' do
      it 'returns the right list of emails which depends on the settings set by the user' do
        expect(mail_chimp_account.relevant_emails.size).to eq(2)
        mail_chimp_account.update(sync_all_active_contacts: true)
        expect(mail_chimp_account.relevant_emails.size).to eq(3)
      end
    end

    context '#relevant_contacts' do
      it 'returns the right list of contacts which again depends on the settings set by the user' do
        expect(mail_chimp_account.relevant_contacts.last).to eq(newsletter_contacts.last)
        mail_chimp_account.update(sync_all_active_contacts: true)
        expect(mail_chimp_account.relevant_contacts.last).to eq(non_newsletter_contact)
      end
    end
  end
end
