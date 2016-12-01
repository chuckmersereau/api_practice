class Api::V2::AccountLists::FiltersController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_filters
    render json: @filters
  end

  private

  def load_filters
    @filters = {}
    @filters[:contact_filters] = contact_filters if filter_params[:contact] == '1'
    @filters[:task_filters] = task_filters if filter_params[:task] == '1'
  end

  def contact_filters
    Contact::Filterer.config(filter_scope)
  end

  def task_filters
    Task::Filterer.config(filter_scope)
  end

  def filter_scope
    load_account_list
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    [:contact, :task]
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
