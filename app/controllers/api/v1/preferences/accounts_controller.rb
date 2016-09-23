class Api::V1::Preferences::AccountsController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_account_preferences
  end

  private

  def load_account_preferences
    @preferences.merge!(
      account_lists: current_user.account_lists.select(:id, :name),
      account_list_id: current_account_list.id.try(:to_s)
    )
  end
end
