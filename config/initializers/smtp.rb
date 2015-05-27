ActionMailer::Base.smtp_settings = {
  :user_name => ENV['SMTP_USER_NAME'],
  :password => ENV['SMTP_PASSWORD'],
  :address => ENV['SMTP_ADDRESS'],
  :authentication => (ENV['SMTP_AUTHENTICATION'] || :none),
  :enable_starttls_auto => ENV['SMTP_ENABLE_STARTTLS_AUTO'],
  :port => ENV['SMTP_PORT'] || 25
}
