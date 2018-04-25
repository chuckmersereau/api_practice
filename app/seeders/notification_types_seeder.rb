class NotificationTypesSeeder < ApplicationSeeder
  def seed
    Rails.logger.info "#{self.class}... " unless quiet

    stopped_giving = NotificationType::StoppedGiving.first_or_create
    stopped_giving.update(description: _('Partner missed a gift'), description_for_email: _('Partner missed a gift'))

    started_giving = NotificationType::StartedGiving.first_or_create
    started_giving.update(description: _('Partner started giving'), description_for_email: _('Partner started giving'))

    larger_gift = NotificationType::LargerGift.first_or_create
    larger_gift.update(description: _('Partner gave a larger gift than commitment'),
                       description_for_email: _('Partner gave a larger gift than the commitment recorded in MPDX'))

    special_gift = NotificationType::SpecialGift.first_or_create
    special_gift.update(description: _('Partner gave a Special Gift'),
                        description_for_email: _('Partner gave a Special Gift: This notification is triggered anytime '\
                                                 "someone who does not have a status of 'Partner - Financial' gives a "\
                                                 'gift. If one or more of the people below are financial partners, '\
                                                 'please log into MPDX, edit that contact, and set their status to '\
                                                 "'Partner - Financial'."))

    smaller_gift = NotificationType::SmallerGift.first_or_create
    smaller_gift.update(description: _('Partner gave less than commitment'),
                        description_for_email: _('Partner gave a gift that averages out to less than their commitment'))

    recontinued_gift = NotificationType::RecontinuingGift.first_or_create
    recontinued_gift.update(description: _('Partner recontinued giving'),
                            description_for_email: _('Partner gave a gift to recontinue their giving '\
                                                     'after being two or more months late'))

    long_time_frame_gift = NotificationType::LongTimeFrameGift.first_or_create
    long_time_frame_gift.update(description: _('Partner gave with commitment of semi-annual or more'),
                                description_for_email: _('Partner gave a gift with a long time frame '\
                                                         '(semi-annual, annual, or biennial'))

    call_partner = NotificationType::CallPartnerOncePerYear.first_or_create
    call_partner.update(description: _('Partner have not had an attempted call logged in the past year'),
                        description_for_email: _('It is so important to connect with our financial partners '\
                                                 'personally, but it is easy for time to get away from us. MPDX does '\
                                                 'not show a phone call to your financial partner in the past year. '\
                                                 'Now would be a great time to connect with them!​'))

    thank_partner = NotificationType::ThankPartnerOncePerYear.first_or_create
    thank_partner.update(description: _('Partner have not had a thank you note logged in the past year'),
                         description_for_email: _('One of the most important things we can do is thank our partners, '\
                                                  'but it is easy for time to get away from us. MPDX does not show a '\
                                                  'thank you note for your financial partner in the past year. Now '\
                                                  'would be a great time to let them '\
                                                 'know how much you appreciate them!​'))

    remind_partner = NotificationType::RemindPartnerInAdvance.first_or_create
    remind_partner.update(description: _('Partner (semiannual, annual, etc) has an expected '\
                                         'donation one month from now. Send them a reminder.'),
                          description_for_email: _('It is important to remind our financial partners who give on a '\
                                                   'less frequent basis of their upcoming gift. MPDX shows financial '\
                                                   'partners who have expected donations one month from now. Now would '\
                                                   'be a great time to remind them.'))

    missing_address = NotificationType::MissingAddressInNewsletter.first_or_create
    missing_address.update(description: _('Contact is on the physical newsletter but has no mailing address.'),
                           description_for_email: _('Contacts missing a mailing address'))

    missing_email = NotificationType::MissingEmailInNewsletter.first_or_create
    missing_email.update(description: _('Contact is on the email newsletter but has no people with a valid email address.'),
                         description_for_email: _('Contacts missing an email address'))
  end
end
