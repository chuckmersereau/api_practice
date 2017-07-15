class Reports::GoalProgressSerializer < ServiceSerializer
  delegate :account_list,
           :in_hand_percent,
           :monthly_goal,
           :pledged_percent,
           :received_pledges,
           :salary_balance,
           :salary_currency_or_default,
           :total_pledges,
           to: :object

  belongs_to :account_list

  attributes :in_hand_percent,
             :monthly_goal,
             :pledged_percent,
             :received_pledges,
             :salary_balance,
             :salary_currency_or_default,
             :salary_organization_id,
             :total_pledges

  def salary_organization_id
    Organization.where(id: account_list.salary_organization_id)
                .limit(1)
                .pluck(:uuid)
                .first
  end
end
