require 'rails_helper'

RSpec.describe NewUserTransferWorker do
  let(:user) { create(:user) }
  before do
    ENV['KIRBY_URL'] = 'cru.org'
  end

  describe '#perform' do
    it 'should call RowTransferRequest.transfer' do
      expect(RowTransferRequest).to receive(:transfer).twice
      subject.perform(user.id)
    end

    context 'with DISABLE_KIRBY env var' do
      before do
        ENV['DISABLE_KIRBY'] = 'true'
      end
      after do
        ENV.delete 'DISABLE_KIRBY'
      end

      it "doesn't make any transfer requests" do
        expect(RowTransferRequest).to_not receive(:transfer)
        subject.perform(user.id)
      end
    end
  end
end
