require 'spec_helper'

describe ImportMailer do
  context '#complete' do
    it 'assigns to field correctly' do
      email_address = build(:email_address, email: 't@t.co')
      user = double(email: email_address, locale: 'en')
      import = double(user: user, user_friendly_source: 'tnt')

      mail = ImportMailer.complete(import)

      expect(mail.to).to eq ['t@t.co']
    end
  end
end
