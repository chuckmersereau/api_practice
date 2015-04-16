require 'spec_helper'

describe 'Overall notification tests' do
  let!(:larger_gift) { NotificationType::LargerGift.first_or_create }
  let!(:long_time_frame_gift) { NotificationType::LongTimeFrameGift.first_or_create }
  let!(:recontinuing_gift) { NotificationType::RecontinuingGift.first_or_create }
  let!(:smaller_gift) { NotificationType::SmallerGift.first_or_create }
  let!(:special_gift) { NotificationType::SpecialGift.first_or_create }
  let!(:started_giving) { NotificationType::StartedGiving.first_or_create }
  let!(:stopped_giving) { NotificationType::StoppedGiving.first_or_create }
  let!(:account_list) { create(:account_list) }
  let!(:da) { create(:designation_account) }
  let!(:contact) { create(:contact, status: 'Partner - Financial', account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let(:account_list2) { create(:account_list) }
  let(:weekly) { Contact.pledge_frequencies.find { |_freq, name| name == _('Weekly') }.first }
  let(:fornightly) { Contact.pledge_frequencies.find { |_freq, name| name == _('Fortnightly') }.first }

  before do
    expect($rollout).to receive(:active?).at_least(:once).with(:new_notifications, anything).and_return(true)
    [
      larger_gift, long_time_frame_gift, recontinuing_gift, smaller_gift, special_gift, started_giving, stopped_giving
    ].each do |notification_type|
      account_list.notification_preferences.find_or_create_by(notification_type: notification_type, actions: %w(email task))
    end
    contact.donor_accounts << donor_account
    account_list.designation_accounts << da

    account_list2.account_list_entries.create!(designation_account: da)

    # This is necessary because when we run this spec with others, NotificationType's @@types will get set
    # to an empty array from another spec.
    expect(NotificationType).to receive(:types).at_least(:once).and_return(NotificationType.pluck(:type))
  end

  it 'correctly creates notifications for financial partner giving patterns' do
    {
      { pledge_frequency: nil, amounts: [] } => [],
      { pledge_frequency: nil, amounts: [10] } => [started_giving],
      { pledge_frequency: 1, amounts: [11] } => [larger_gift, started_giving],
      { pledge_frequency: 1, amounts: [10, 11] } => [larger_gift],
      { pledge_frequency: 1, amounts: [20, 10] } => [],
      { pledge_frequency: 1, amounts: [5, 10] } => [],
      { pledge_frequency: 1, amounts: [10, 11, 0] } => [larger_gift],
      { pledge_frequency: 1, amounts: [10, 0, 0, 0] } => [stopped_giving],
      { pledge_frequency: 1, amounts: [10, 0, 0, 10, 20] } => [],
      { pledge_frequency: 1, amounts: [9] } => [smaller_gift, started_giving],
      { pledge_frequency: 1, amounts: [10, 9] } => [smaller_gift],
      { pledge_frequency: 1, amounts: [10] } => [started_giving],
      { pledge_frequency: 1, amounts: [10, 10] } => [],
      { pledge_frequency: 1, amounts: [10, 0, 20] } => [],
      { pledge_frequency: 1, amounts: [10, 0, 21] } => [larger_gift],
      { pledge_frequency: 1, amounts: [10, 0, 0, 0, 40] } => [recontinuing_gift],
      { pledge_frequency: 1, amounts: [10, 0, 0, 10] } => [recontinuing_gift],
      { pledge_frequency: 1, amounts: [10, 0, 0, 0, 41] } => [larger_gift, recontinuing_gift],
      { pledge_frequency: 1, amounts: [10, 0, 0, 0, 10, 11] } => [larger_gift],
      { pledge_frequency: 1, amounts: [10] + Array.new(10, 0) + [20] } => [recontinuing_gift],
      { pledge_frequency: 1, amounts: [10] + Array.new(13, 0) + [20] } => [recontinuing_gift],
      { pledge_frequency: weekly, amounts: [10] } => [started_giving],
      { pledge_frequency: weekly, amounts: [10, 10, 10, 10] } => [],
      { pledge_frequency: weekly, amounts: [10, 200] } => [larger_gift, started_giving],
      { pledge_frequency: weekly, amounts: [10, 10, 10, 10, 10, 200] } => [larger_gift],
      { pledge_frequency: weekly, amounts: [10] + Array.new(9, 0) } => [stopped_giving],
      { pledge_frequency: weekly, amounts: [10] + Array.new(14, 0) + [10] } => [recontinuing_gift],
      { pledge_frequency: weekly, amounts: [10, 10, 20, 0] } => [larger_gift],
      { pledge_frequency: weekly, amounts: [20] } => [larger_gift, started_giving],
      { pledge_frequency: weekly, amounts: [5] } => [smaller_gift, started_giving],
      { pledge_frequency: weekly, amounts: [10, 5] } => [smaller_gift, started_giving],
      { pledge_frequency: weekly, amounts: [10, 10, 10, 10, 10, 5] } => [smaller_gift],
      { pledge_frequency: weekly, amounts: [10, 0] } => [started_giving],
      { pledge_frequency: fornightly, amounts: [20] } => [started_giving],
      { pledge_frequency: fornightly, amounts: [20, 0, 20, 0, 20] } => [],
      { pledge_frequency: 2, amounts: [20, 0, 20] } => [],
      { pledge_frequency: 2, amounts: [20, 0, 0, 0, 0] } => [stopped_giving],
      { pledge_frequency: 2, amounts: [20, 20] } => [larger_gift],
      { pledge_frequency: 2, amounts: [20, 0, 21] } => [larger_gift],
      { pledge_frequency: 2, amounts: [20, 0, 0, 30] } => [larger_gift],
      { pledge_frequency: 2, amounts: [20, 0, 0, 0, 30] } => [recontinuing_gift],
      { pledge_frequency: 2, amounts: [20, 0, 0, 0, 40] } => [recontinuing_gift],
      { pledge_frequency: 2, amounts: [20, 0, 0, 0, 41] } => [larger_gift, recontinuing_gift],
      { pledge_frequency: 3, amounts: [30, 0, 0, 30] } => [],
      { pledge_frequency: 3, amounts: [30, 0, 0, 0, 35] } => [larger_gift],
      { pledge_frequency: 3, amounts: [30, 0, 0, 0, 0, 35] } => [larger_gift, recontinuing_gift],
      { pledge_frequency: 3, amounts: [35] } => [larger_gift, started_giving],
      { pledge_frequency: 6, amounts: [60] } => [started_giving],
      { pledge_frequency: 6, amounts: [60, 0, 0, 0, 0, 0, 60] } => [long_time_frame_gift],
      { pledge_frequency: 6, amounts: [60, 0, 0, 0, 0, 0, 70] } => [larger_gift],
      { pledge_frequency: 6, amounts: [60] + Array.new(7, 0) + [60] } => [long_time_frame_gift],
      { pledge_frequency: 6, amounts: [70] } => [larger_gift, started_giving],
      { pledge_frequency: 6, amounts: [50] } => [smaller_gift, started_giving],
      { pledge_frequency: 12, amounts: [130] } => [larger_gift, started_giving],
      { pledge_frequency: 12, amounts: [120] } => [started_giving],
      { pledge_frequency: 12, amounts: [120, 10] } => [larger_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(11, 0) + [130] } => [larger_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(11, 0) + [120] } => [long_time_frame_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(12, 0) + [110] } => [smaller_gift],
      { pledge_frequency: 12, amounts: [120, 10] } => [larger_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(11, 0) + [121] } => [larger_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(14, 0) } => [stopped_giving],
      { pledge_frequency: 12, amounts: [120] + Array.new(14, 0) + [121] } => [larger_gift],
      { pledge_frequency: 12, amounts: [120] + Array.new(14, 0) + [120] } => [long_time_frame_gift]
    }.each do |giving, notification_types|
      Donation.destroy_all
      Notification.destroy_all

      setup_giving_info(giving)

      if stopped_giving.in?(notification_types) || recontinuing_gift.in?(notification_types)
        contact.update_column(:pledge_received, true)
        contact.reload
      end

      NotificationType.check_all(account_list.reload)
      msg = "Pledge frequency: #{giving[:pledge_frequency]}, amounts: #{giving[:amounts]}"
      notifications_produced = Notification.all.map(&:notification_type).sort_by(&:id)
      expected_notifications = notification_types.sort_by(&:id)
      expect(notifications_produced).to eq(expected_notifications), msg

      # It shouldn't add a notification if the contact is on a different account list with a shared designation account
      expect(NotificationType.check_all(account_list2)).to be_empty
    end
  end

  def setup_giving_info(giving)
    if giving[:pledge_frequency].nil?
      pledge_amount = nil
    else
      pledge_amount = 10 * (giving[:pledge_frequency] >= 1 ? giving[:pledge_frequency] :
          giving[:pledge_frequency] / weekly)
    end
    contact.update_columns(pledge_frequency: giving[:pledge_frequency] || 1, last_donation_date: nil,
                           pledge_amount: pledge_amount, first_donation_date: nil, pledge_received: false)

    giving[:amounts].reverse.each_with_index do |amount, i|
      next if amount == 0
      donation_date = (giving[:pledge_frequency] || 1) < 1 ? Date.today - (7 * i) : Date.today << i
      d = create(:donation, amount: amount, donation_date: donation_date, designation_account: da,
                            donor_account: donor_account)
      contact.update_donation_totals(d)
    end
  end
end
