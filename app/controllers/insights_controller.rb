class InsightsController < ApplicationController
  before_action :ensure_rollout

  def index
    @page_title = _('Insights')
    @recommnds = InsightAnalyses.new.increase_recommendation_analysis( current_account_list.designation_accounts.pluck(:designation_number).first)["rowset"]["Row"]
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

  private

  def ensure_rollout
    return if $rollout.active?(:insights, current_account_list)
    fail ActionController::RoutingError.new('Not Found'), 'Insights access is not granted.'
  end
end