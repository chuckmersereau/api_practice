class RunOncePreview < ActionMailer::Preview
  def fix_newsletter_status
    RunOnceMailer.fix_newsletter_status('bill.bright@cru.org', -1, 'Staff Account')
  end

  def new_mailchimp_list
    RunOnceMailer.new_mailchimp_list('bill.bright@cru.org', -1, 'Staff Account', 'https://us1.admin.mailchimp.com/lists/members/?id=1234')
  end
end
