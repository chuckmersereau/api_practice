class Api::V1::Preferences::NotificationsController < Api::V1::BaseController
  before_action :load_preferences_set

  def index
    load_notification_preferences
    render json: { preferences: @preferences }, callback: params[:callback]
  end

  protected

  def load_notification_preferences
    @preferences = {}
    NotificationType.all.each do |notification_type|
      field_name = notification_type.class.to_s.split('::').last.to_s.underscore.to_sym
      @preferences.merge!(field_name => {
                            actions: [('email' if @preference_set.send(field_name).include?('email')),
                                      ('task' if @preference_set.send(field_name).include?('task')),
                                      '']
                          })
    end
  end

  def load_preferences_set
    @preference_set = PreferenceSet.new(user: current_user, account_list: current_account_list)
  end
end
