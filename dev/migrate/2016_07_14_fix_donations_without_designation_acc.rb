require 'logger'
class AddAccountsToDonations
  @logger = nil
  def add_accounts_to_donations(last_donor_id = 0)
    log_action_for_donor(nil, 0)
    last_id = 0
    donor_accounts(last_donor_id).limit(800).each do |donor_account|
      last_id = donor_account.id

      if donor_account.contacts && donor_account.contacts.map(&:account_list_id).uniq.count == 1
        account_list = donor_account.contacts.first.account_list
      else
        log_action_for_donor(donor_account, 1)
        next
      end

      org_accounts = donor_org_accounts(account_list)
      unless org_accounts.count == 1
        log_action_for_donor(donor_account, 2)
        next
      end

      org_account = org_accounts.first
      designation_account = org_account_designation_account(org_account)
      unless designation_account
        log_action_for_donor(donor_account, 3)
        next
      end

      donor_account.donations.where(designation_account_id: nil).update_all(designation_account_id: designation_account.id)
      log_action_for_donor(donor_account, 4)
    end

    log_action_for_donor(nil, 5)
    FixDonationsWorker.perform_async(last_id) if last_id > 0
  end

  private

  def donations_without_designation_accounts
    Donation.where(designation_account_id: nil)
  end

  def donor_accounts(last_donor_id = 0)
    DonorAccount.joins(:donations)
                .where(donations: { designation_account_id: nil })
                .group('donor_accounts.id')
                .order('donor_accounts.id asc')
                .where('donor_accounts.id > ?', last_donor_id)
  end

  def donor_org_accounts(account_list)
    account_list.organization_accounts.select do |oa|
      account_list.creator_id == oa.person_id
    end
  end

  def org_account_designation_account(org_account)
    DesignationAccount.find_by(
      organization_id: org_account.organization_id,
      active: true,
      designation_number: org_account.id.to_s)
  end

  def log_action(donation, status)
    logger.info("Start script at #{Time.now}") if status == 0
    logger.info("Don. ##{donation.id}: DonorAcc has more than 1 Contact.") if status == 1
    logger.info("Don. ##{donation.id}: AccountList has more than 1 OrgAcc.") if status == 2
    logger.info("Don. ##{donation.id}: DesignationAcc was not found for OrgAcc.") if status == 3
    logger.info("Don. ##{donation.id}: DesignationAcc was added to donation.") if status == 4
    logger.info("End of script at #{Time.now}") if status == 5
  end

  def log_action_for_donor(donor_account, status)
    logger.info("Start script at #{Time.now}") if status == 0
    logger.info("DA. ##{donor_account.id}: DonorAcc has more than 1 Contact.") if status == 1
    logger.info("DA. ##{donor_account.id}: AccountList has more than 1 OrgAcc.") if status == 2
    logger.info("DA. ##{donor_account.id}: DesignationAcc was not found for OrgAcc.") if status == 3
    logger.info("DA. ##{donor_account.id}: DesignationAcc was added to donations.") if status == 4
    logger.info("End of script at #{Time.now}") if status == 5
  end

  def logger
    @logger ||= Logger.new('log/2016_07_14_fix_donations_without_designation_acc.log', 10, 1_024_000_000)
  end
end
