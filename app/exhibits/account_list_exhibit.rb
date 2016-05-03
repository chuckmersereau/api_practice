class AccountListExhibit < DisplayCase::Exhibit
  include LocalizationHelper

  def self.applicable_to?(object)
    object.class.name == 'AccountList'
  end

  def to_s
    designation_accounts.map(&:name).join(', ')
  end

  def multi_currencies_for_same_symbol?
    @multi_currencies_for_same_symbol ||=
      begin
        symbols = currencies.map { |c| currency_symbol(c) }.uniq
        symbols.size < currencies.size
      end
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

    totals_by_currency = {}

    main_balance = 0.0
    balance_currency = salary_currency || default_currency ||
                       designation_accounts.first&.currency

    designation_accounts.select(&:active).each do |da|
      next if da.balance.blank?
      totals_by_currency[da.currency] ||= 0.0
      totals_by_currency[da.currency] += da.balance
      next if da.currency != balance_currency
      main_balance += da.balance
    end

    balances_widget(main_balance, balance_currency, totals_by_currency)
  end

  private

  def balances_widget(main_balance, balance_currency, totals_by_currency)
    balance = @context.number_to_current_currency(main_balance, currency: balance_currency)
    balance_text = format(_('Balance: %{balance}'), balance: balance)
    tooltip = _('May take a few days to update')

    if totals_by_currency.count > 1
      tooltip += "\n#{_('All balances:')} #{format_currency_subtotals(totals_by_currency)}"
    end

    balances_html(tooltip, balance_text)
  end

  def format_currency_subtotals(totals_by_currency)
    totals_by_currency.map do |currency, sub_total|
      @context.number_to_current_currency(sub_total, currency: currency, show_code: true)
    end.join('; ')
  end

  def balances_html(tooltip, balance_text)
    "<div class='account_balances tip' title='#{tooltip}'>#{balance_text}</div>".html_safe
  end
end
