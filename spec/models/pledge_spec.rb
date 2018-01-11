require 'rails_helper'

RSpec.describe Pledge, type: :model do
  subject! { create(:pledge) }
  let(:appeal) { create(:appeal) }

  it { is_expected.to belong_to(:account_list) }
  it { is_expected.to belong_to(:appeal) }
  it { is_expected.to belong_to(:contact) }
  it { is_expected.to have_many(:pledge_donations).dependent(:destroy) }
  it { is_expected.to have_many(:donations).through(:pledge_donations) }
  it { is_expected.to validate_presence_of(:account_list) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:contact) }
  it { is_expected.to validate_presence_of(:expected_date) }

  it 'sets PERMITTED_ATTRIBUTES' do
    expect(described_class::PERMITTED_ATTRIBUTES).to eq(
      [
        :amount,
        :amount_currency,
        :appeal_id,
        :created_at,
        :contact_id,
        :donation_id,
        :expected_date,
        :overwrite,
        :status,
        :updated_at,
        :updated_in_db_at,
        :uuid
      ]
    )
  end

  context '#appeal' do
    let(:contact) { create(:contact) }

    it 'restricted to a single entry per contact per appeal' do
      create(:pledge, appeal: appeal, contact: contact)

      expect { subject.update!(appeal: appeal, contact: contact) }.to \
        raise_error ActiveRecord::RecordInvalid
    end
  end

  context '#merge' do
    let!(:loser_pledge) { create(:pledge, appeal: appeal) }

    it 'moves donations' do
      subject.update(appeal: appeal)
      subject.donations << create(:donation)
      loser_pledge.donations << create(:donation)

      expect { subject.merge(loser_pledge) }.to change { subject.donations.count }.from(1).to(2)
    end

    it "won't merge if appeals don't match" do
      expect { subject.merge(loser_pledge) }.to change(Pledge, :count).by(0)

      subject.update(appeal: appeal)

      expect { subject.merge(loser_pledge) }.to change(Pledge, :count).by(-1)
    end

    it 'combines pledge amount if loser has higher amount' do
      subject.update(appeal: appeal)
      loser_pledge.update(amount: 100)

      expect { subject.merge(loser_pledge) }.to change { subject.reload.amount }
    end

    it "doesn't move attributes if loser has lower amount" do
      subject.update(appeal: appeal)
      loser_pledge.update(amount: 5)

      expect { subject.merge(loser_pledge) }.to_not change { subject.reload.amount }
    end
  end
end
