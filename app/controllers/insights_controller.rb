class InsightsController < ApplicationController

  def index
    @page_title = _('Insights')
    @current_user = current_user
    @recommnds = InsightAnalyses.new.recommendations( current_account_list.designation_accounts.pluck(:designation_number).first)[:rowset][:Row]
  end

end