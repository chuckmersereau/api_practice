class Api::V1::InsightsController < Api::V1::BaseController
  def index
    render json: insights_analyses_contacts, callback: params[:callback]
  end

  private

  def insights_analyses_contacts
    desig = current_account_list.designation_accounts.pluck(:designation_number).first
    Contact.where(account_list_id: current_account_list, id: current_account_list.contacts.joins(:donor_accounts).
        where(donor_accounts: {account_number: InsightAnalyses.new.increase_recommendation_contacts(desig)}).
        pluck('contacts.id')).pluck('id')
  end
end
