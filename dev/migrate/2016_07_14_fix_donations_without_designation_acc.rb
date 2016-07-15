require 'logger'
class AddAccountsToDonations

  @logger = nil
  def add_accounts_to_donations
    log_action(nil, 0)

    donations_without_designation_accounts.find_each do |donation|
      unless donation.donor_account.contacts.count == 1
        log_action(donation, 1)
        next
      end

      org_accounts = donor_org_accounts(donation.donor_account.contacts.first.account_list)
      unless org_accounts.count == 1
        log_action(donation, 2)
        next
      end

      org_account = org_accounts.first
      designation_account = org_account_designation_account(org_account)
      unless designation_account
        log_action(donation, 3)
        next
      end

      donation.update(designation_account_id: designation_account.id)
      log_action(donation, 4)
    end

    log_action(nil, 5)
  end

  #private

  def donations_without_designation_accounts
    Donation.where(designation_account_id: nil)
  end

  def donor_org_accounts(account_list)
    account_list.organization_accounts.select{ |oa|
      account_list.creator_id == oa.person_id
    }
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

  def logger
    @logger ||= Logger.new('log/2016_07_14_fix_donations_without_designation_acc.log', 10, 1024000000)
  end
end
