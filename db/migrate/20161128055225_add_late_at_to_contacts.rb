class AddLateAtToContacts < ActiveRecord::Migration
  class Contact < ActiveRecord::Base
    before_save :update_late_at
    scope :financial_partners, -> { where(status: 'Partner - Financial') }

    def update_late_at
      initial_date = last_donation_date || pledge_start_date
      return unless status == 'Partner - Financial' && pledge_frequency.present? && initial_date.present?
      self.late_at = case
                     when pledge_frequency >= 1.0
                       initial_date + pledge_frequency.to_i.months
                     when pledge_frequency >= 0.4
                       initial_date + 2.weeks
                     else
                       initial_date + 1.week
                     end
    end
  end

  def up
    add_column :contacts, :late_at, :date
    Contact.financial_partners.map(&:save)
  end

  def down
    remove_column :contacts, :late_at
  end
end
