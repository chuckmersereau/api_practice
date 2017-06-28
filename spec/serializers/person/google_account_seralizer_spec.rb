require 'rails_helper'

describe Person::GoogleAccountSerializer do
  let(:google_account) { create(:google_account) }

  subject { Person::GoogleAccountSerializer.new(google_account).as_json }
  before { allow_any_instance_of(Person::GoogleAccount).to receive(:contact_groups).and_return([]) }

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
