FactoryBot.define do
  factory :contact_referral do
    referred_by { FactoryBot.create(:contact) }
    referred_to { FactoryBot.create(:contact) }
  end
end
