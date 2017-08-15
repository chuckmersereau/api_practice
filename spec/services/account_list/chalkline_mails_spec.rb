require 'rails_helper'

RSpec.describe AccountList::ChalklineMails, type: :model do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:service) { AccountList::ChalklineMails.new(account_list: account_list) }

  describe 'initialize' do
    subject { service }

    it 'initializes successfully' do
      expect(subject).to be_a AccountList::ChalklineMails
      expect(subject.account_list).to eq account_list
    end
  end

  describe '#send_later' do
    before do
      Sidekiq::Testing.fake!
    end

    subject { service.send_later }

    it 'enqueues a new background job' do
      expect(ChalklineMailer).to receive_message_chain(:delay, :mailing_list).with(account_list)
      subject
    end
  end
end
