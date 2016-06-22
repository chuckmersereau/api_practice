class Api::V1::PrayerLettersAccountsController < Api::V1::BaseController
  def destroy
    load_prayer_letters_account
    @prayer_letters_account.destroy
    render json: { success: true }
  end

  def sync
    load_prayer_letters_account
    @prayer_letters_account.queue_subscribe_contacts
    render json: { success: true }
  end

  private

  def load_prayer_letters_account
    @prayer_letters_account ||= current_account_list.prayer_letters_account
  end
end
