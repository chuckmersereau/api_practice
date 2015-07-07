require 'spec_helper'

describe NotificationType::SpecialGift do
  let!(:special_gift) { NotificationType::SpecialGift.first_or_initialize }
  let!(:da) { create(:designation_account_with_special_donor) }
  let(:contact) { da.contacts.non_financial_partners.first }
  let(:donation) { create(:donation, donor_account: contact.donor_accounts.first, designation_account: da, donation_date: 5.days.ago) }

  context '#check' do
    it 'adds a notification if a gift comes from a non financial partner' do
      donation # create donation object from let above
      notifications = special_gift.check(contact.account_list)
      expect(notifications.length).to eq(1)
    end

    it "doesn't add a notification if first gift came more than 2 weeks ago" do
      create(:donation, donor_account: contact.donor_accounts.first, designation_account: da, donation_date: 37.days.ago)
      notifications = special_gift.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end

    it "doesn't add a notification if the contact is on a different account list with a shared designation account" do
      donation # create donation object from let above
      account_list2 = create(:account_list)
      account_list2.account_list_entries.create!(designation_account: da)
      notifications = special_gift.check(account_list2)
      expect(notifications.length).to eq(0)
    end
  end

  describe '.create_task' do
    let(:account_list) { create(:account_list) }

    it 'creates a task for the activity list' do
      expect do
        special_gift.create_task(account_list, contact.notifications.new(donation_id: donation.id))
      end.to change(Activity, :count).by(1)
    end

    it 'associates the contact with the task created' do
      task = special_gift.create_task(account_list, contact.notifications.new(donation_id: donation.id))
      expect(task.contacts.reload).to include contact
    end
  end
end
