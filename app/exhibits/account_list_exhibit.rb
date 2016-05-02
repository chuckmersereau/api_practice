class AccountListExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'AccountList'
  end

  def to_s
    designation_accounts.map(&:name).join(', ')
  end

  # This code is being kept temporarily to allow a slow rollout of the new
  # multi-currency and simplified balance calculation.
  def old_balances_calc(user)
    return '' if designation_accounts.empty?
    if designation_accounts.length > 1
      balance =
        if designation_profile(user).try(:balance)
          designation_profile(user).balance.to_i
        else
          account_list_entries.map { |e| e.designation_account.try(:balance).to_i }.reduce(&:+)
        end
    else
      balance = designation_accounts.first.balance.to_i
    end
    "<div class='account_balances tip' title='#{_('May take a few days to update')}'>#{_('Balance: %{balance}').localize % { balance: @context.number_to_current_currency(balance) }}</div>".html_safe
  end

  def balances
    return '' if designation_accounts.empty?

    tooltip = _('May take a few days to update')
    if designation_organizations.count > 1
      # For someone with multiple organizations, we only show the primary
      # organization's balance. To make that clearer to the use, change the
      # text, provide a link to the balances report and an explanation in the
      # tooltip.
      balance_text = _('Primary Balance: %{balance}')
      tooltip += "\n" + _('Click to see all balances')
      link_to_report = true
    else
      balance_text = _('Balance: %{balance}')
      link_to_report = false
    end
    balances_html(format(balance_text, balance: formatted_balance), tooltip, link_to_report)
  end

  private

  def formatted_balance
    balance = designation_accounts.where(organization_id: salary_organization_id)
                                  .where(active: true).sum(:balance)
    @context.number_to_current_currency(balance, currency: salary_currency)
  end

  def balances_html(balance_text, tooltip, link_to_report)
    html = "<div class='account_balances tip' title='#{tooltip}'>#{balance_text}</div>"
    html = "<a href=\"#{@context.reports_balances_path}\">#{html}</a>" if link_to_report
    html.html_safe
  end
end
