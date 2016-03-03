require 'spec_helper'

describe TntImport::SettingsImport do
  let(:xml) do
    TntImport::XmlReader.new(tnt_import).parsed_xml
  end
  let(:tnt_import) { create(:tnt_import, override: true) }
  let(:account_list) { tnt_import.account_list }
  let(:import) do
    TntImport::SettingsImport.new(tnt_import.account_list, xml, true)
  end

  context '#import_settings' do
    it 'updates monthly goal' do
      expect do
        import.import
      end.to change(account_list, :monthly_goal).from(nil).to(6300)
    end
  end

  context '#import_mail_chimp' do
    it 'creates a mailchimp account' do
      expect do
        import.import_mail_chimp('asdf', 'asasdfdf-us4', false)
      end.to change(MailChimpAccount, :count).by(1)
    end

    it 'updates a mailchimp account' do
      account_list.create_mail_chimp_account(api_key: '5', primary_list_id: '6')
      expect do
        import.import_mail_chimp('1', '2', true)
      end.to change(account_list.mail_chimp_account, :api_key).from('5').to('2')
    end
  end
end
