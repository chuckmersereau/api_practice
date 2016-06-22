class Api::V1::PrayerLettersAccountsController < ApplicationController
  def destroy
    prayer_letters_account.destroy
    render nothing: true
  end

  def sync
    prayer_letters_account.queue_subscribe_contacts
    redirect_to :back
  end

  private

  def prayer_letters_account
    @prayer_letters_account ||= current_account_list.prayer_letters_account ||
                                current_account_list.build_prayer_letters_account
  end
end
