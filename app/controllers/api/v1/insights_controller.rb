class Api::V1::InsightsController < Api::V1::BaseController
  def index
    render json: recommended_contacts, callback: params[:callback]
  end

  private

  def recommended_contacts

    recommends = InsightAnalyses.new.recommendations( current_account_list.designation_accounts.pluck(:designation_number).first)[:rowset][:Row]

    r_contacts = Array.new

    recommends.each do |c, v|
      r_contacts.push( c[:Column8].to_s )
    end

    Contact.where(account_list_id: current_account_list, id:  current_account_list.contacts.joins(:donor_accounts).where(donor_accounts: {account_number: r_contacts}).pluck('contacts.id')).pluck('id')

  end

end