class FixDuplicateDonations
  include Sidekiq::Worker

  sidekiq_options queue: :api_default, retry: 3

  MATCH_ATTRIBUTES = %i(amount donation_date tendered_currency).freeze

  def perform(designation_account_id)
    @designation_account = DesignationAccount.find(designation_account_id)
    return unless @designation_account

    @cleaned_donations = []
    log_worker_progress do
      donations_scope.find_each(&method(:cleanup_donation))
    end
    send_email
  end

  private

  def log_worker_progress
    pre_count = donations_scope.count
    start_time = Time.zone.now
    log(format('Started at %p', start_time))

    yield

    post_count = donations_scope.count
    changed_ids = donations_scope.where('updated_at >= ?', start_time).pluck(:id)

    log(format('Finished Job after %d seconds', Time.zone.now - start_time))
    log(format('Donation.count: before<%p>, after<%p>, delta<%p>',
               pre_count, post_count, pre_count - post_count))
    log(format('Updated Donations<ids: %p>', changed_ids))
  end

  def cleanup_donation(d)
    matches = find_donations(d).to_a

    return if matches.empty?

    Donation.transaction do
      # only try to move appeal if there isn't already a match
      link_appeal(d, matches) if d.appeal_id && matches.none? { |m| m.appeal_id == d.appeal_id }

      donor_account = d.donor_account

      destroy_donation(d)

      destroy_donor_account(donor_account)
    end
  end

  def destroy_donation(donation)
    memo = "Moved from Designation Account #{donation.designation_account_id}, "\
           "Account List #{account_list.id}; "\
           "Donor Account #{donation.donor_account.account_number} #{donation.donor_account.name}; "\
           "#{donation.memo}"
    donation.update!(designation_account: temp_designation_account, donor_account: temp_donor_account, memo: memo)

    @cleaned_donations << donation
  end

  def temp_donor_account
    return @temp_donor_account if @temp_donor_account
    name = 'MPDX-4335 Duplicate Donation Pot'
    org = Organization.find_by(name: 'MPDX Trainers') || Organization.first
    @temp_donor_account = DonorAccount.find_or_create_by(name: name, organization: org, account_number: '-1')
  end

  def temp_designation_account
    return @temp_designation_account if @temp_designation_account
    name = 'MPDX-4335 Duplicate Donation Pot'
    org = Organization.find_by(name: 'MPDX Trainers') || Organization.first
    @temp_designation_account = DesignationAccount.find_or_create_by(name: name, organization: org)
  end

  def destroy_donor_account(donor_account)
    donor_account.destroy unless donor_account.donations.exists?
  end

  def account_list
    @account_list ||= @designation_account.account_lists.order(:created_at).first
  end

  def find_contact(donation)
    @contact_cache ||= {}
    return @contact_cache[donation.donor_account_id] if @contact_cache[donation.donor_account_id]
    @contact_cache[donation.donor_account_id] = donation.donor_account.contacts.find_by(account_list: account_list)
  end

  def find_donations(donation)
    match_attributes = donation.attributes.with_indifferent_access.slice(*MATCH_ATTRIBUTES)
    match_attributes[:appeal_id] = [donation.appeal_id, nil] if donation.appeal_id

    contact = find_contact(donation)
    return unless contact
    contact.donations
           .where(match_attributes)
           .where.not(designation_account_id: donation.designation_account_id)
  end

  def link_appeal(donation, matches)
    new_appeal_donation = matches.find { |d| d.appeal_id.blank? || d.appeal_id == donation.appeal_id }
    new_appeal_donation.update!(appeal_id: donation.appeal_id, appeal_amount: donation.appeal_amount)
  end

  def donations_scope
    @designation_account.donations
  end

  def send_email
    return if @cleaned_donations.empty?
    addresses = account_list.users.collect(&:email_address).uniq.compact
    return if addresses.empty?
    mail = ActionMailer::Base.mail(from: 'support@mpdx.org',
                                   to: addresses,
                                   subject: 'MPDX - Duplicate Donations Merged',
                                   body: email_body)
    mail.deliver_later
  end

  def email_body
    'Hi friend! We wanted to drop you a line to let you know that we ran a process to clean up '\
    "the extra donations we had imported from your TNT Export. We identified #{@cleaned_donations.count} "\
    "donations that were already in your account \"#{account_list.name}\". If you find that you are "\
    "missing donations, please let us know (we've tucked them away for safe keeping). Additionally, "\
    'if you still see a handful of duplicates, please clean them up by deleting the "This donation '\
    'was imported from Tnt." donation. If there are more than a handful that remain, please reach '\
    "out to us and we'll take another round to clean them up.

     Have a great day!

     Your MPDX Team
     support@mpdx.org".gsub(/ +/, ' ')
  end

  def log(message)
    # Because the sidekiq config sets the logging level to Fatal, log to fatal
    # so that we can see these in the logs
    Rails.logger.fatal("DonationDups[worker]: #{message}")
  end
end
