namespace :adobe_campaigns do
  task signup: :environment do
    User.where(current_sign_in_at: 1.year.ago..Time.now.utc).find_each { |u| u.send(:enqueue_adobe_campaign_subscription) }
  end
end
