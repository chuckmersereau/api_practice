class InsightsController < ApplicationController

  def index
    @page_title = _('Insights')
    @recommnds = InsightAnalyses.new.increase_recommendation_analysis( current_account_list.designation_accounts.pluck(:designation_number).first)["rowset"]["Row"]
    @recommnds = InsightAnalyses.new.increase_recommendation_analysis('0124650')["rowset"]["Row"]
    @recurring_recommnds = RecurringRecommendationResults
   end

  def create
    @recurring_recommnds.create(account_list_id: current_account_list.id,contact_id: "#{recurr_contact_id}",result: params[:selected_result] )
  end

end