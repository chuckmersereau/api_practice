module ParamsFilters
  extend ActiveSupport::Concern

  included do
    def current_account_list
      @current_account_list = params[:account_list_id] ? AccountList.find(params[:account_list_id]) : nil
    end

    def current_appeal
      @current_appeal = params[:appeal_id] ? current_account_list.appeals.find(params[:appeal_id]) : nil
    end
  end
end
