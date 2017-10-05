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

  def weeks_on_mpd
    if active_mpd_start_at.present? && active_mpd_finish_at.present?
      seconds = (active_mpd_finish_at - active_mpd_start_at).days
      seconds / 1.week
    end
  end

  def last_prayer_letter_at
    mail_chimp_account&.prayer_letter_last_sent
  end

  def formatted_balance(locale: nil)
    balance = designation_accounts.where(organization_id: salary_organization_id)
                                  .where(active: true).sum(:balance)
    @context.number_to_current_currency(balance, currency: salary_currency,
                                                 locale: locale)
  end

  def staff_account_ids
    designation_accounts.map(&:staff_account_id).compact
  end
end
