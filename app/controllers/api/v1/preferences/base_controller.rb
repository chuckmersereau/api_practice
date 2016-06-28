class Api::V1::Preferences::BaseController < Api::V1::BaseController
  before_action :load_preferences

  def index
    render json: { preferences: @preferences }, callback: params[:callback]
  end

  protected

  def load_preferences
    @preferences ||= {}
  end

  def preference_set
    @preference_set ||= PreferenceSet.new(user: current_user, account_list: current_account_list)
  end
end
