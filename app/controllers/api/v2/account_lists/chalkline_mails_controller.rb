class Api::V2::AccountLists::ChalklineMailsController < Api::V2Controller
  def create
    authorize_chalkline_mails
    load_chalkline_mails
    send_chalkline_mails
    render_chalkline_mails
  end

  private

  def authorize_chalkline_mails
    authorize(load_account_list, :show?)
  end

  def account_lists_scope
    account_lists
  end

  def load_account_list
    @account_list ||= account_lists_scope.find_by!(uuid: params[:account_list_id])
  end

  def load_chalkline_mails
    @chalkline_mails ||= AccountList::ChalklineMails.new(account_list: load_account_list)
  end

  def send_chalkline_mails
    load_chalkline_mails.send_later
  end

  def permitted_filters
    []
  end

  def render_chalkline_mails
    render json: @chalkline_mails,
           status: success_status
  end
end
