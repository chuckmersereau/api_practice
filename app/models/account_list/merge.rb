class AccountList::Merge
  def initialize(winner, loser)
    @winner = winner
    @loser = loser
  end

  def merge
    AccountList.transaction { merge_fields_and_associations }
  end

  private

  def merge_fields_and_associations
    # Intentionally don't copy over notification_preferences since they may conflict between accounts
    [:activities, :appeals, :company_partnerships, :contacts, :designation_profiles,
     :google_integrations, :help_requests, :imports, :messages, :recurring_recommendation_results
    ].each { |has_many| @loser.send(has_many).update_all(account_list_id: @winner.id) }

    [:mail_chimp_account, :prayer_letters_account].each do |has_one|
      next unless @winner.send(has_one).nil? && @loser.send(has_one).present?
      @loser.send(has_one).update(account_list_id: @winner.id)
    end

    [:designation_accounts, :companies].each do |copy_if_missing|
      @loser.send(copy_if_missing).each do |item|
        @winner.send(copy_if_missing) << item unless @winner.send(copy_if_missing).include?(item)
      end
    end

    @loser.users.each do |user|
      next if users.include?(user)
      users << user
      user.update(preferences: nil)
    end

    @loser.reload
    @loser.destroy

    @winner.save(validate: false)

    deactivate_dup_designations
  end

  def deactivate_dup_designations
    designations = @winner.designation_accounts.reload
    return unless DesignationAccount::DupByBalanceFix.deactivate_dups(designations)

    # If a dup designation account is found and deactivated, re-run the donor
    # import to fix balances for the designation profiles so that the users
    # won't see incorrect balances for long.
    @winner.async(:import_data)
  end
end
