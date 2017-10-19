require 'rails_helper'

RSpec.describe Pledge, type: :model do
  subject { create(:pledge) }

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
end
