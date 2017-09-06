require 'rails_helper'

RSpec.describe AccountListCoach, type: :model do
  subject { create(:account_list_coach) }
  it { is_expected.to belong_to(:coach) }
  it { is_expected.to belong_to(:account_list) }
end
