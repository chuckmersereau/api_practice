class Api::V1::Preferences::NotificationsController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_notification_preferences
  end

  private

  def load_notification_preferences
    NotificationType.all.each do |notification_type|
      field_name = notification_type.class.to_s.split('::').last.to_s.underscore.to_sym
      @preferences.merge!(field_name => {
                            actions: [('email' if preference_set.send(field_name).include?('email')),
                                      ('task' if preference_set.send(field_name).include?('task')),
                                      '']
                          })
    end
  end
end
