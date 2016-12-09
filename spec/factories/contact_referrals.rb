FactoryGirl.define do
  factory :contact_referral do
    referred_by { FactoryGirl.create(:contact) }
    referred_to { FactoryGirl.create(:contact) }
  end
end
