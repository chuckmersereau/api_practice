class Reports::MonthlyGivingGraphExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'Reports::MonthlyGivingGraph'
  end

  def salary_currency_symbol
    currency_symbol(salary_currency)
  end
end
