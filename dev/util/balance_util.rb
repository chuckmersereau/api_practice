class DummyContext
  def number_to_current_currency(x)
    "$#{x}"
  end
end

def balance(a, u)
  e = AccountListExhibit.new(a, DummyContext.new)
  e.balances(u)
end

def fix_dup_balance(u)
  u.account_lists.each do |a|
    fix_dup_balance(a)
  end
end

def fix_dup_balance(a)
  balance_to_account = {}
  a.designation_accounts.order(created_at: :desc).each do |da|
    next unless da.balance.present?
    if balance_to_account[da.balance].present?
      da.update!(active: false)
    else
      balance_to_account[da.balance] = da
    end
  end
  a.async(:import_data)
end
