class CoachingAccountListSerializer < AccountListSerializer
  include DisplayCase::ExhibitsHelper
  include LocalizationHelper

  delegate :last_prayer_letter_at,
           :staff_account_ids,
           :weeks_on_mpd,
           to: :account_list_exhibit

  attributes :balance,
             :committed,
             :last_prayer_letter_at,
             :progress,
             :received,
             :staff_account_ids,
             :weeks_on_mpd

  has_many :users, serializer: CoachedPersonSerializer

  def account_list_exhibit
    @exhibit ||= exhibit(object)
  end

  def balance
    locale = current_user&.locale if respond_to?(:current_user)
    account_list_exhibit.formatted_balance(locale: locale || 'en')
  end

  def committed
    account_list_exhibit.total_pledges
  end

  def received
    account_list_exhibit.received_pledges
  end

  def progress
    Reports::GoalProgressSerializer.new(goal_progress)
                                   .to_h
                                   .except(:account_list) # redundant
  end

  private

  def goal_progress
    Reports::GoalProgress.new(account_list: object)
  end
end
