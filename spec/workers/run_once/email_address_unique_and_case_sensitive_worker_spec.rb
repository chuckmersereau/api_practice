require 'rails_helper'

RSpec.describe RunOnce::EmailAddressUniqueAndCaseSensitiveWorker do
  let(:mail_chimp_account) { create(:mail_chimp_account) }
  let!(:mail_chimp_member_1) { create(:mail_chimp_member, mail_chimp_account_id: mail_chimp_account.id) }
  let!(:mail_chimp_member_2) do
    create(:mail_chimp_member, mail_chimp_account_id: mail_chimp_account.id, email: 'test123@example.com')
  end

  describe '#perform' do
    context 'duplicates exist' do
      before do
        mail_chimp_member_1.update_columns(email: 'Test123@example.com', created_at: 1.week.ago)
      end

      it 'destroys the older of the duplicates' do
        expect do
          described_class.new.perform
        end.to change(MailChimpMember, :count).by(-1)
        expect(MailChimpMember.exists?(mail_chimp_member_2.id)).to be true
      end
    end

    context 'no duplicates exist' do
      it "doesn't destroy any accounts" do
        expect do
          described_class.new.perform
        end.to change(MailChimpMember, :count).by(0)
      end
    end
  end
end
