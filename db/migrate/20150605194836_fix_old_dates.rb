class FixOldDates < ActiveRecord::Migration
  def change
    Contact.where(next_ask: Date.parse('1899-12-30')).update_all(next_ask: nil)
    Contact.where(pledge_start_date: Date.parse('1899-12-30')).update_all(pledge_start_date: nil)
    Contact.where(last_activity: Date.parse('1899-12-30')).update_all(last_activity: nil)
    Contact.where(last_appointment: Date.parse('1899-12-30')).update_all(last_appointment: nil)
    Contact.where(last_letter: Date.parse('1899-12-30')).update_all(last_letter: nil)
    Contact.where(last_phone_call: Date.parse('1899-12-30')).update_all(last_phone_call: nil)
    Contact.where(last_pre_call: Date.parse('1899-12-30')).update_all(last_pre_call: nil)
    Contact.where(last_thank: Date.parse('1899-12-30')).update_all(last_thank: nil)
  end
end
