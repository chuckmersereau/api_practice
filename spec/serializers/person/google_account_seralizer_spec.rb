require 'rails_helper'

describe Person::GoogleAccountSerializer do
  let(:google_account) { create(:google_account) }

  subject { Person::GoogleAccountSerializer.new(google_account).as_json }

  it { is_expected.to include :id }
  it { is_expected.to include :email }
  it { is_expected.to include :expires_at }
  it { is_expected.to include :last_download }
  it { is_expected.to include :last_email_sync }
  it { is_expected.to include :primary }
  it { is_expected.to include :remote_id }
  it { is_expected.to include :token_expired }
  it { is_expected.to include :created_at }
  it { is_expected.to include :updated_at }
  it { is_expected.to include :updated_in_db_at }

  describe '#token_expired' do
    context 'token expired' do
      before { allow(google_account).to receive(:token_expired?).and_return(true) }
      it { expect(subject[:token_expired]).to eq true }
    end
    context 'token not expired' do
      before { allow(google_account).to receive(:token_expired?).and_return(false) }
      it { expect(subject[:token_expired]).to eq false }
    end
  end
end
