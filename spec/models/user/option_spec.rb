require 'rails_helper'

RSpec.describe User::Option, type: :model do
  let(:user) { create(:user_with_account) }
  subject { create(:user_option, user: user) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:user_id) }
  it { is_expected.to have_db_column(:key).of_type(:string) }
  it { is_expected.to have_db_column(:value).of_type(:string) }
  it { is_expected.to have_db_column(:user_id).of_type(:integer) }
  it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
  it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
  it { is_expected.to have_db_index([:key, :user_id]).unique(true) }
  it { is_expected.to have_db_index(:uuid).unique(true) }
  it { is_expected.to allow_value('snake_case').for(:key) }
  it { is_expected.to allow_value('camelCase').for(:key) }
  it { is_expected.to_not allow_value('Title Case').for(:key) }
end
