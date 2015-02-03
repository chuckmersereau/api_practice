class InsightsController < ApplicationController

  def index
    @page_title = _('Insights')
    #@recommnds = InsightAnalyses.new.increase_recommendation_analysis( current_account_list.designation_accounts.pluck(:designation_number).first)["rowset"]["Row"]
    @recommnds = InsightAnalyses.new.increase_recommendation_analysis( '0124650')["rowset"]["Row"]
    @recurring_recommnds = RecurringRecommendationResults
   end

  def create
    results = RecurringRecommendationResults.new
    results.contact_id = params[:selectedRecurringContactId].to_i
    results.account_list_id = current_account_list.id
    results.result = params[:selResult]
    results.save
    redirect_to insights_path
  end

end