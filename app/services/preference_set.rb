class PreferenceSet
  include Virtus.model
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Serializers

  attr_reader :user, :account_list

  def initialize(*args)
    attributes = args.first
    @user = attributes[:user]
    @account_list = attributes[:account_list]

    attributes[:first_name] ||= @user.first_name
    attributes[:last_name] ||= @user.last_name
    attributes[:email] ||= @user.email.try(:email)
    super
  end

  # User preferences
  attribute :first_name, String, default: -> (preference_set, _attribute) { preference_set.user.first_name }
  attribute :last_name, String, default: -> (preference_set, _attribute) { preference_set.user.last_name }
  attribute :email, String, default: -> (preference_set, _attribute) { preference_set.user.email }
  attribute :time_zone, String, default: -> (preference_set, _attribute) { preference_set.user.time_zone }
  attribute :locale, String, default: -> (preference_set, _attribute) { preference_set.user.locale }
  attribute :monthly_goal, String, default: -> (preference_set, _attribute) { preference_set.account_list.monthly_goal }
  attribute :default_account_list, Integer, default: -> (preference_set, _attribute) { preference_set.user.default_account_list }
  attribute :tester, Boolean, default: -> (preference_set, _attribute) { preference_set.account_list.tester }
  attribute :setup, String, default: -> (preference_set, _attribute) { preference_set.user.setup }
  attribute :home_country,
            String, default: -> (preference_set, _attribute) { preference_set.account_list.home_country }
  attribute :ministry_country,
            String, default: -> (preference_set, _attribute) { preference_set.account_list.ministry_country }
  attribute :currency,
            String, default: -> (preference_set, _attribute) { preference_set.account_list.currency }
  attribute :salary_organization_id,
            Integer, default: -> (preference_set, _attribute) { preference_set.account_list.salary_organization_id }
  attribute :account_list_name, String,
            default: -> (preference_set, _attribute) { preference_set.account_list.name }

  # AccountList preferences
  # - Notification Preferences
  attribute :notification_preferences, Array[NotificationPreference]

  validates :first_name, presence: true
  validates :email, presence: true, email: true

  def persisted?
    false
  end

  NotificationType.types.each do |type|
    method_name = (type.split('::').last.underscore + '=').to_sym
    define_method method_name do |val|
      set_preference(type, val)
    end
  end

  def notification_settings
  end

  def notification_settings=(val)
    # reload preferences at this point
    account_list.notification_preferences(true)
    NotificationType.all.find_each do |type|
      next if !$rollout.active?(:missing_info_notifications, account_list) &&
              type.type.in?(%w(NotificationType::MissingEmailInNewsletter NotificationType::MissingAddressInNewsletter))
      pref = account_list.notification_preferences.find_or_initialize_by(notification_type_id: type.id)
      pref.actions = which_notification_setting(type.type, val)
      pref.save if pref.actions_changed?
    end
  end

  def which_notification_setting(type, group_val)
    return [''] if group_val != 'default' ||
                   %w(NotificationType::CallPartnerOncePerYear NotificationType::ThankPartnerOncePerYear).include?(type)
    NotificationPreference.default_actions
  end

  def save
    if valid?
      persist!
      true
    else
      false
    end
  end

  # Handle our dynamic list of notification types
  def method_missing(method, *args, &blk) # {{{
    class_name = 'NotificationType::' + method.to_s.camelize
    if NotificationType.types.include?(class_name)
      type = class_name.constantize.first
      account_list.notification_preferences.find { |p| p.notification_type_id == type.id }.try(:actions) ||
        NotificationPreference.default_actions
    else
      super
    end
  end

  def respond_to?(method, include_private = false)
    class_name = 'NotificationType::' + method.to_s.camelize
    NotificationType.types.include?(class_name) || super
  end

  private

  def set_preference(klass, val)
    type = klass.constantize.first
    preference = account_list.notification_preferences.find { |p| p.notification_type_id == type.id } ||
                 account_list.notification_preferences.new(notification_type_id: type.id)
    preference.actions = val['actions']
    preference.save
  end

  def persist!
    user.update_attributes(first_name: first_name, last_name: last_name, email: email, time_zone: time_zone,
                           locale: locale, default_account_list: default_account_list, setup: setup_array)
    account_list.update(monthly_goal: monthly_goal, tester: tester, home_country: home_country,
                        currency: currency, name: account_list_name,
                        salary_organization_id: salary_organization_id)
    account_list.save
  end

  def setup_array
    return setup unless setup.is_a? String
    setup.gsub(/\[|\]|:/, '').split(', ').map(&:to_sym)
  end
end