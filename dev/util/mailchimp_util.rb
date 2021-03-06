def schedule_sync(mc_account, index)
  id = mc_account.id
  num_secs = index * 60
  MailChimpAccount.perform_in(num_secs.seconds, id, :call_mail_chimp, :export_to_primary_list)
end

def backup_mc_account(mc_account)
  puts mc_account.id
  json = {
    account_list: mc_account.account_list,
    members: mc_account.list_members(mc_account.primary_list_id)
  }.to_json
  filename = "mc_backup/#{mc_account.id}.json"
  File.open(filename, 'w') { |file| file.write(json) }
rescue StandardError => e
  puts e
end

# this class exists to help understand the state of data synced (or not synced) to a Mailchimp.
class MailChimpReport
  @report = {}

  attr_reader :report, :not_in_mailchimp, :mailchimp_dups, :wrapper

  def run(account_list, list_id = nil)
    if account_list.is_a? AccountList
      mca = account_list.mail_chimp_account
    elsif account_list.is_a? MailChimpAccount
      mca = account_list
      account_list = mca.account_list
    else
      raise 'needs an account list or mailchimp account'
    end
    raise 'no active mailchimp account' unless mca&.active
    list_id ||= mca.primary_list_id
    raise 'no primary_list_id' unless list_id

    @wrapper = MailChimp::GibbonWrapper.new(mca)
    members = @wrapper.list_members(list_id)
    members.each { |member| member['email_address'] = member['email_address'].downcase }

    @mailchimp_dups = members.group_by { |member| member['email_address'] }
                             .select { |_, group| group.count > 1 }

    account_list_emails = EmailAddress.joins(person: [:contacts])
                                      .where(contacts: { account_list_id: account_list.id })
    active_emails = account_list_emails.where(historic: false)
    primary_emails = active_emails.where(primary: true)
    non_opt_out_people_emails = primary_emails.where(people: { optout_enewsletter: false })
    newsletter_emails = non_opt_out_people_emails.where(contacts: { send_newsletter: %w(Email Both) })

    @report = {}
    members.each do |member|
      email = member['email_address']
      next add_to_list(:newsletter_contacts, member) if newsletter_emails.exists?(email: email)
      next add_to_list(:active_contacts, member) if non_opt_out_people_emails.exists?(email: email)
      next add_to_list(:opted_out, member) if primary_emails.exists?(email: email)
      next add_to_list(:non_primary, member) if active_emails.exists?(email: email)
      next add_to_list(:inactive_email, member) if account_list_emails.exists?(email: email)
      add_to_list(:not_in_mpdx, member)
    end

    @not_in_mailchimp = newsletter_emails.pluck(:email) - members.map { |member| member['email_address'] }
    print_report
    nil
  end

  private

  def add_to_list(list, member)
    @report[list] ||= { subscribed: [], unsubscribed: [], manual_unsubscribed: [], cleaned: [], pending: [] }
    status = member['status'].to_sym
    status = :manual_unsubscribed if status == :unsubscribed && !MailChimpMember.mpdx_unsubscribe?(member)
    @report[list][status] << member
  end

  def puts_counts(list)
    unless @report[list]
      puts 'None'
      puts ' '
      return
    end
    puts @report[list].transform_values(&:count)
    bad_category = list == :newsletter_contacts ? :unsubscribed : :subscribed
    puts @report[list][bad_category].map { |member| member['email_address'] } if @report[list][bad_category].any?
    puts ' '
  end

  def print_report
    if @mailchimp_dups.keys.any?
      puts '=========='
      puts 'Duplicate emails in mailchimp:'
      puts @mailchimp_dups.keys
    end
    if @not_in_mailchimp.any?
      puts '=========='
      puts 'Emails in MPDX but not in mailchimp:'
      puts 'We can try to resubscribe them if you agree they should be in Mailchimp.'
      puts @not_in_mailchimp
    end

    puts '=========='
    puts 'Newsletter contacts:'
    puts 'These email addresses are primary on a contact that has newsletter set to either Email or Both.'
    puts 'We can try to resubscribe them if you think they were unsubscribed in error.'
    puts_counts :newsletter_contacts

    puts 'Active Contacts (Physical or none newsletter):'
    puts_counts :active_contacts

    puts 'Opted Out = true:'
    puts 'These emails addresses are primary on a person in MPDX who is labeled '\
         'with "Opt-out of Email Newsletter", but are subscribed on Mailchimp.'
    puts 'They should either be unsubscribed on Mailchimp if they asked you to mark them as such,'
    puts 'or that flag should be removed in MPDX if they should be subscribed.'
    puts_counts :opted_out

    puts 'Non-primary email addresses:'
    puts 'These emails addresses are non-primary on people in MPDX, but are subscribed in Mailchimp.'
    puts 'We can unsubscribe them on Mailchimp if they are old email addresses.'
    puts_counts :non_primary

    puts 'Historic Emails:'
    puts 'These emails addresses are marked as "Invalid" in MPDX, but are subscribed in Mailchimp.'
    puts 'We can unsubscribe them on Mailchimp if they are old email addresses.'
    puts_counts :inactive_email

    puts 'Not in MPDX:'
    puts 'These email addresses are subscribed on Mailchimp, but are not in MPDX.'
    puts "We suggest adding them to a contact in MPDX so they don't fall through the cracks."
    puts_counts :not_in_mpdx
  end
end

# something like
# set_member_status('bill.bright@cru.org', :unsubscribed, mca, mca.primary_list_id)
# or
# set_member_status(@wrapper.list_members(list_id).first, 'subscribed', mca)
def set_member_status(member, status, mail_chimp_account, list_id = nil)
  email = if member.is_a? String
            member
          else
            member['email_address']
          end
  return unless email

  list_id ||= member['list_id']

  gibbon = Gibbon::Request.new(api_key: mail_chimp_account.api_key, debug: true)

  gibbon.lists(list_id).members(mail_chimp_account.email_hash(email)).update(body: { status: status.to_s })
end
