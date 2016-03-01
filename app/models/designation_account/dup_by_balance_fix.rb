class DesignationAccount::DupByBalanceFix
  class << self
    # This should take a scoped activerecord relation for the designation
    # accounts to deactivate by dup balance, i.e. the designation_accounts for
    # an account list
    def deactivate_dups(designation_accounts)
      any_account_deactivated = false

      accounts_by_balance(designation_accounts).each do |_balance, accounts|
        # Deactivate all but the first designation account for a balance group
        accounts[1..-1].each do |da|
          da.update!(active: false, balance: 0)
          any_account_deactivated = true
        end
      end

      any_account_deactivated
    end

    private

    def accounts_by_balance(designation_accounts)
      ordered_designations(designation_accounts).group_by(&:balance)
    end

    def ordered_designations(designation_accounts)
      designation_accounts.where.not(balance: nil).where.not(balance: 0.0)
        .order("CASE WHEN name LIKE '% and %' THEN 0 ELSE 1 END")
        .order(created_at: :desc).to_a
    end
  end
end
