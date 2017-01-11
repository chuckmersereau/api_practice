class AccountList::AnalyticsSerializer < ServiceSerializer
  attributes :appointments,
             :contacts,
             :correspondence,
             :electronic,
             :email,
             :end_date,
             :facebook,
             :phone,
             :text_message,
             :start_date

  delegate :appointments,
           :contacts,
           :correspondence,
           :electronic,
           :email,
           :facebook,
           :text_message,
           :phone,
           to: :object

  belongs_to :account_list
end
