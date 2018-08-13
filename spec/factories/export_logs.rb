FactoryBot.define do
  factory :export_log do
    type 'Contacts Export'
    params 'filter[account_list_id]=1'
    user { User.first || create(:user) }
    export_at '2017-07-28 15:19:32'
  end
end
