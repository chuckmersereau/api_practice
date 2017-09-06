require 'rails_helper'

RSpec.describe Balance, type: :model do
  subject { create(:balance) }
  it { is_expected.to have_db_index([:resource_id, :resource_type]) }
  it { is_expected.to belong_to(:resource) }
  it { is_expected.to validate_presence_of(:resource) }
  it { is_expected.to validate_presence_of(:balance) }
end
