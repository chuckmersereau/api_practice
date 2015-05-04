class NotificationType::ThankPartnerOncePerYear < NotificationType::TaskIfPeriodPast
  def check_contacts_filter(contacts)
    super(contacts).where('pledge_frequency < ?', LongTimeFrameGift::LONG_TIME_FRAME_PLEDGE_FREQUENCY)
  end

  def task_description_template
    '%{contact_name} have not had a thank you note logged in the past year.  Send them a Thank You note.'
  end

  def task_activity_type
    'Thank'
  end
end
