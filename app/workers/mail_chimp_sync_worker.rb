class MailChimpSyncWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true, unique: true

  CURRENT_USER_RANGE = 180.days.ago

  def perform(*)
    # Subscribe anyone who has logged in in the past [CURRENT_USER_RANGE] days
    User.includes(:primary_email_address).where(
      'sign_in_count > 0 and current_sign_in_at > ? and subscribed_to_updates IS NULL', CURRENT_USER_RANGE
    ).find_each do |u|
      if u.email
        vars = { EMAIL: u.email.email.strip, FNAME: u.first_name, LNAME: u.last_name }
        begin
          gb.list_subscribe(id: ENV.fetch('MAILCHIMP_LIST'), email_address: vars[:EMAIL], update_existing: true,
                            double_optin: false, merge_vars: vars, send_welcome: false, replace_interests: true)
          u.update_column(:subscribed_to_updates, true)

        rescue Gibbon::MailChimpError => e
          case
          when e.message.include?('code 502'), e.message.include?('code -99')
            # Invalid email address
            u.update_column(:subscribed_to_updates, false)
          else
            raise
          end
        end
      end
    end

    # Unsubscribe anyone who has NOT logged in in the past [CURRENT_USER_RANGE] days
    User.includes(:primary_email_address).where(
      'sign_in_count > 0 and current_sign_in_at < ? and subscribed_to_updates = ?', CURRENT_USER_RANGE, true
    ).find_each do |u|
      if u.email
        begin
          gb.list_unsubscribe(id: ENV.fetch('MAILCHIMP_LIST'), email_address: u.email.email,
                              send_goodbye: false, delete_member: true)
          u.update_column(:subscribed_to_updates, nil)
          Rails.logger.debug "Unsubscribed #{u.first_name} #{u.last_name} - #{u.email.email}"
        rescue Gibbon::MailChimpError => e
          case
          when e.message.include?('code 232')
            # Email address is already unsubscribed
            u.update_column(:subscribed_to_updates, false)
          else
            raise
          end
        end
      end
    end
  end

  def gb
    @gb ||= Gibbon.new(ENV.fetch('MAILCHIMP_KEY'))
  end
end
