class DonationSyncsController < ApplicationController
  def create
    current_account_list.async(:import_data)
    flash[:notice] = _('Donation sync initiated successfully and will start soon')
    redirect_to donations_path('ga-action': 'Sync Donations Now')
  end
end
