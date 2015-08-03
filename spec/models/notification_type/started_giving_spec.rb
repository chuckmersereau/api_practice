require 'spec_helper'

describe NotificationType::StartedGiving do
  let!(:started_giving) { NotificationType::StartedGiving.first_or_initialize }
  let!(:da) { create(:designation_account_with_donor) }
  let(:contact) { da.contacts.financial_partners.first }
  let(:donation) { create(:donation, donor_account: contact.donor_accounts.first, designation_account: da, donation_date: 5.days.ago) }

  context '#check' do
    before { contact.update_column(:direct_deposit, true) }

    it 'adds a notification if first gift came within past 2 weeks' do
      donation # create donation object from let above
      notifications = started_giving.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it 'adds a notification if first gift came within past 2 weeks even if donor has given to another da' do
      other_da = create(:designation_account_with_special_donor)
      create(:donation, donor_account: contact.donor_accounts.first, designation_account: other_da, donation_date: 20.days.ago)
      donation # create donation object from let above
      notifications = started_giving.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it "doesn't add a notification if not first gift" do
      2.times do |i|
        create(:donation, donor_account: contact.donor_accounts.first, designation_account: da, donation_date: (i * 30).days.ago)
      end
      notifications = started_giving.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it "doesn't add a notification if first gift came more than 2 weeks ago" do
      create(:donation, donor_account: contact.donor_accounts.first, designation_account: da, donation_date: 37.days.ago)
      notifications = started_giving.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    describe 'sets pledge_received if first gift came in the past pledge_frequency period' do
      before { contact.update(pledge_amount: 9.99) }

      it 'marks pledge received if monthly and donation within one month' do
        contact.update(pledge_frequency: 1)

        donation = create_donation(6.months.ago)
        expect_pledge_received(false)

        donation.update(donation_date: 15.days.ago)
        expect_pledge_received(true)
      end

      it 'marks pledge received if annual and donation within one year' do
        contact.update(pledge_frequency: 12)

        donation = create_donation(2.years.ago)
        expect_pledge_received(false)

        donation.update(donation_date: 6.months.ago)
        expect_pledge_received(true)
      end

      it 'works if pledge frequency is a fraction' do
        contact.update(pledge_frequency: 0.5)
        create_donation(1.day.ago)
        expect_pledge_received(true)
      end

      def create_donation(donation_date)
        create(:donation, donor_account: contact.donor_accounts.first,
                          designation_account: da, donation_date: donation_date)
      end

      def expect_pledge_received(expected_val)
        started_giving.check(contact.account_list)
        expect(contact.reload.pledge_received).to be expected_val
      end
    end

    it "doesn't add a notification if the contact is on a different account list with a shared designation account" do
      donation # create donation object from let above
      account_list2 = create(:account_list)
      account_list2.account_list_entries.create!(designation_account: da)
      notifications = started_giving.check(account_list2)
      expect(notifications.length).to eq(0)
    end

    it 'sets pledge received and defaults to a monthly pledge when first gift given for financial partner ' do
      contact.update(pledge_amount: nil, pledge_frequency: nil, pledge_received: false)
      donation
      started_giving.check(contact.account_list)
      contact.reload
      expect(contact.pledge_amount).to eq(9.99)
      expect(contact.pledge_frequency).to eq(1)
      expect(contact.pledge_received).to be true
    end
  end

  describe '.create_task' do
    let(:account_list) { create(:account_list) }

    it 'creates a task for the activity list' do
      expect do
        started_giving.create_task(account_list, contact.notifications.new)
      end.to change(Activity, :count).by(1)
    end

    it 'associates the contact with the task created' do
      task = started_giving.create_task(account_list, contact.notifications.new)
      expect(task.contacts.reload).to include contact
    end
  end
end
