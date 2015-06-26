require 'spec_helper'

describe NotificationType::RemindPartnerInAdvance do
  let!(:remind_partner_in_advance) { NotificationType::RemindPartnerInAdvance.first_or_initialize }
  let!(:da) { create(:designation_account_with_donor) }
  let(:contact) { da.contacts.financial_partners.first }
  let(:donation) do
    create(:donation, donor_account: contact.donor_accounts.first, designation_account: da,
                      donation_date: 2.months.ago)
  end

  describe '#check' do
    context 'non-direct deposit donor' do
      before do
        contact.update(direct_deposit: false, pledge_received: true, pledge_frequency: 3.0)
      end

      it 'adds a notification if one month in advance' do
        donation.update(donation_date: 2.month.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(1)
      end

      it "doesn't adds a notification if 32 days late" do
        donation.update(donation_date: 122.days.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end

      it "doesn't adds a notification if one month in advance but pledge_frequency is nil" do
        contact.update(pledge_frequency: nil)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end

      it 'skips people with future pledge_start_date' do
        contact.update(pledge_start_date: 1.day.from_now)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end

      it "doesn't add a notification if not one month in advance" do
        donation.update(donation_date: 1.month.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end

      it 'add a notification if less than one month in advance' do
        donation.update(donation_date: 65.days.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(1)
      end

      it "doesn't add a notification if less than one month in advance with a recent prior notification" do
        donation.update(donation_date: 65.days.ago)
        contact.update(last_donation_date: donation.donation_date)
        contact.notifications.create!(notification_type_id: remind_partner_in_advance.id,
                                      event_date: 1.month.ago)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end

      it 'add a notification if less than one month in advance with a remote prior nodifiction' do
        donation.update(donation_date: 65.days.ago)
        contact.update(last_donation_date: donation.donation_date)
        contact.notifications.create!(notification_type_id: remind_partner_in_advance.id,
                                      event_date: 3.month.ago)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(1)
      end

      it "doesn't add a notification if the contact is on a different account list with a shared designation account" do
        donation.update(donation_date: 2.month.ago)
        contact.update(last_donation_date: donation.donation_date)
        account_list2 = create(:account_list)
        account_list2.account_list_entries.create!(designation_account: da)
        notifications = remind_partner_in_advance.check(account_list2)
        expect(notifications.length).to eq(0)
      end
    end

    context 'has never given' do
      it "doesn't add a notification" do
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end
    end

    context 'direct deposit donor' do
      before do
        contact.update(direct_deposit: true, pledge_received: true, pledge_frequency: 3.0)
      end

      it "doesn't adds a notification if one month in advance" do
        donation.update(donation_date: 2.months.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end
    end

    context 'less than quarterly donor' do
      before do
        contact.update(direct_deposit: false, pledge_received: true, pledge_frequency: 1.0)
      end

      it "doesn't adds a notification if one month in advance" do
        donation.update(donation_date: 2.months.ago)
        contact.update(last_donation_date: donation.donation_date)
        notifications = remind_partner_in_advance.check(contact.account_list)
        expect(notifications.length).to eq(0)
      end
    end
  end

  describe '#create_task' do
    let(:account_list) { create(:account_list) }

    it 'creates a task for the activity list' do
      expect do
        remind_partner_in_advance.create_task(account_list, contact.notifications.new)
      end.to change(Activity, :count).by(1)
    end

    it 'associates the contact with the task created' do
      task = remind_partner_in_advance.create_task(account_list, contact.notifications.new)
      expect(task.contacts.reload).to include(contact)
    end
  end
end
