class Reports::GoalProgress < ActiveModelSerializers::Model
  attr_accessor :account_list

  delegate :designation_accounts,
           :in_hand_percent,
           :monthly_goal,
           :pledged_percent,
           :received_pledges,
           :salary_currency_or_default,
           :salary_organization_id,
           :total_pledges,
           to: :account_list

  def salary_balance
    designation_accounts.where(organization_id: salary_organization_id).where(active: true).to_a.sum do |designation_account|
      designation_account.converted_balance(salary_currency_or_default)
    end
  end
end
