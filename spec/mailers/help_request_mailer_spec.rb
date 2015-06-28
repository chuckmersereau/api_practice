require 'spec_helper'

describe HelpRequestMailer do
  describe 'email' do
    let(:help_request) { build(:help_request) }
    let(:mail) { HelpRequestMailer.email(help_request) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Problem')
      expect(mail.to).to eq(['support@mpdx.org'])
      expect(mail.from).to eq([help_request.email])
    end
  end
end
