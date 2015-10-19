class CleanContactNewsletterData < ActiveRecord::Migration
  def change
    execute("update contacts set send_newsletter = '' where send_newsletter = 'none'")
    execute("update contacts set send_newsletter = 'Physical' where send_newsletter = 'physical'")
  end
end
