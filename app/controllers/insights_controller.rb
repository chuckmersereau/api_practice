class InsightsController < ApplicationController

  def index
    @page_title = _('Insights')
    #@recommnds = InsightAnalyses.new.increase_recommendation_analysis( current_account_list.designation_accounts.pluck(:designation_number).first)[:rowset][:Row]
    @recommnds = InsightAnalyses.new.increase_recommendation_analysis( '0124650')[:rowset][:Row]
  end

end