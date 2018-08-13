FactoryBot.define do
  factory :access_token, class: 'Doorkeeper::AccessToken' do
    resource_owner_id
    application_id
    token { double acceptable?: true }
  end
end
