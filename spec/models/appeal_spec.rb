require 'spec_helper'

describe Appeal do
  let(:account_list) { create(:account_list) }
  let(:appeal) { create(:appeal, account_list: account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:da) { create(:designation_account) }

  before do
    account_list.designation_accounts << da
  end

  context '#add_contacts_by_opts' do
    it 'adds contacts found by contacts_by_opts' do
      opts = [['Partner - Pray'], ['tag'], {}]
      expect(appeal).to receive(:contacts_by_opts).with(*opts).and_return([contact])
      expect do
        appeal.add_contacts_by_opts(*opts)
      end.to change(appeal.contacts, :count).from(0).to(1)
      expect(appeal.contacts.first).to eq(contact)
    end
  end

  context '#bulk_add_contacts' do
    it 'bulk adds the contacts but removes duplicates first and does not create dups when run again' do
      contact2 = create(:contact)
      expect do
        appeal.bulk_add_contacts([contact, contact, contact2])
      end.to change(appeal.contacts, :count).from(0).to(2)

      expect do
        appeal.bulk_add_contacts([contact, contact, contact2])
      end.to_not change(appeal.contacts, :count).from(2)
    end
  end

  context '#contacts_by_opts' do
    let(:donor_account) { create(:donor_account) }
    let(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }

    before do
      contact.donor_accounts << donor_account
    end

    it 'finds contacts with specified statuses or tags' do
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], {}).count).to eq(1)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], {})).to include(contact)

      expect(appeal.contacts_by_opts(['Partner - Financial'], ['tag'], {}).count).to eq(1)
      contact.update_column(:status, 'Not Interested')
      expect(appeal.contacts_by_opts(['Partner - Financial'], ['tag'], {}).count).to eq(0)
      contact.tag_list = ['tag']
      contact.save
      expect(appeal.contacts_by_opts(['Partner - Financial'], ['tag'], {}).count).to eq(1)
    end

    it 'does not have an error with nil parameters' do
      expect(appeal.contacts_by_opts(nil, nil, nil).count).to eq(0)
    end

    it 'does not find duplicate contacts if contact has multiple tags' do
      contact.tag_list = %w(tagt tag2)
      contact.save
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], {}).count).to eq(1)
    end

    it 'excludes no appeals field if specified' do
      contact.update_column(:no_appeals, true)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], {}).count).to eq(1)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], doNotAskAppeals: true).count).to eq(0)
    end

    it 'excludes joined team last 3 months if specified' do
      contact.update_column(:first_donation_date, 4.months.ago)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], joinedTeam3months: true).count).to eq(1)

      contact.update_column(:pledge_amount, 50)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], joinedTeam3months: true).count).to eq(1)

      contact.update_column(:first_donation_date, 2.months.ago)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], joinedTeam3months: true).count).to eq(0)
      expect(appeal.excluded_appeal_contacts.first.contact).to eq contact

      expect(appeal.contacts_by_opts(['Partner - Financial'], [], {}).count).to eq(1)
    end

    it 'does not exclude contacts with a nil pledge amount' do
      contact.update_columns(pledge_amount: nil, first_donation_date: nil)

      expect(appeal.contacts_by_opts(['Partner - Financial'], [],
                                     joinedTeam3months: true).count).to eq(1)
    end

    it 'excludes special givers in the past 3 months if specified' do
      contact.tag_list = ['tag']
      contact.save
      contact.update(pledge_amount: 50, pledge_frequency: 1, status: 'Partner - Pray')
      donation.update(amount: 500, donation_date: 2.months.ago)

      expect(appeal.contacts_by_opts([], ['tag'], {}).count).to eq(1)
      expect(appeal.contacts_by_opts([], ['tag'], specialGift3months: true).count).to eq(0)
      expect(appeal.excluded_appeal_contacts.first.contact).to eq contact

      donation.update(amount: 150)
      expect(appeal.contacts_by_opts([], ['tag'], specialGift3months: true).count).to eq(1)

      donation.update(donation_date: Date.today << 3)
      donation2 = create(:donation, amount: 50, donation_date: Date.today, designation_account: da)
      donor_account.donations << donation2
      contact.update_donation_totals(donation2)
      expect(appeal.contacts_by_opts([], ['tag'], specialGift3months: true).count).to eq(1)

      donation2.update(amount: 51)
      expect(appeal.contacts_by_opts([], ['tag'], specialGift3months: true).count).to eq(0)
      expect(appeal.excluded_appeal_contacts.first.contact).to eq contact

      donation2.update(designation_account: nil)
      expect(appeal.contacts_by_opts([], ['tag'], specialGift3months: true).count).to eq(1)
    end

    it 'does not exclude contacts with duplicate donor account links' do
      # create duplicate donor account
      contact.contact_donor_accounts.create(donor_account: donor_account)
      contact.update(pledge_amount: 50, pledge_frequency: 1, status: 'Partner - Financial')
      donation.update(amount: 100, donation_date: 2.months.ago)

      expect(appeal.contacts_by_opts(['Partner - Financial'], [], specialGift3months: true).count).to eq(1)
    end

    it 'excludes contacts who stopped giving in the past 2 months if specified' do
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(1)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(1)

      donation2 = create(:donation, amount: 25, donation_date: 3.months.ago, designation_account: da)
      donor_account.donations << donation2
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(1)

      contact.update(pledge_amount: 0, last_donation_date: 3.months.ago)

      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(1)

      donation3 = create(:donation, amount: 25, donation_date: 4.months.ago, designation_account: da)
      donation4 = create(:donation, amount: 25, donation_date: 5.months.ago, designation_account: da)
      donor_account.donations << donation3
      donor_account.donations << donation4
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(0)
      expect(appeal.excluded_appeal_contacts.first.contact).to eq contact

      donation2.update(designation_account: nil)
      donation3.update(designation_account: nil)
      expect(appeal.contacts_by_opts(['Partner - Financial'], [], stoppedGiving2months: true).count).to eq(1)
    end

    it 'excludes contacts who increased giving in the past 3 months if specified' do
      {
        { amounts: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2], pledge_frequency: 1 } => false,
        { amounts: [1, 1, 1], pledge_frequency: 1 } => false,
        { amounts: [1, 1, 2], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 2, 2, 0], pledge_frequency: 1 } => true,
        { amounts: [1, 2, 2, 2, 0], pledge_frequency: 1 } => true,
        { amounts: [1, 0, 0, 0, 0, 0, 0, 0, 1], pledge_frequency: 1 } => false,
        { amounts: [1, 1, 1, 2, 1], pledge_frequency: 1 } => false,
        { amounts: [100, 1, 1, 1, 1, 1, 1, 1], pledge_frequency: 1 } => false,
        { amounts: [100, 1, 1, 1, 1, 1, 2, 2], pledge_frequency: 1 } => true,
        { amounts: [1, 2, 1, 2, 1, 4], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 0, 0, 0, 1], pledge_frequency: 1 } => false,
        { amounts: [1, 1, 1, 1, 2, 0], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 1, 1, 2, 2, 0], pledge_frequency: 1 } => true,
        { amounts: [1, 2, 1, 2, 1, 4], pledge_frequency: 2 } => true,
        { amounts: [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 2], pledge_frequency: 1 } => true,
        { amounts: [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 2], pledge_frequency: 3 } => true,
        { amounts: [1, 2, 1, 2, 1], pledge_frequency: 1 } => false,
        { amounts: [1, 1, 1, 0, 2], pledge_frequency: 1 } => false,
        { amounts: [0, 0, 1, 0, 0, 1, 0, 0, 2, 0, 0, 2], pledge_frequency: 3 } => false,
        { amounts: [1, 2, 1, 2, 1, 2], pledge_frequency: 1 } => true,
        { amounts: [1, 1, 1, 2, 0, 0], pledge_frequency: 1 } => false
      }.each do |giving_info, increased|
        import_giving_info(giving_info)

        expect(appeal.contacts_by_opts(['Partner - Financial'], [], increasedGiving3months: true).count)
          .to eq(increased ? 0 : 1)

        if increased
          expect(appeal.excluded_appeal_contacts.first.contact).to eq contact
        end

        donor_account.donations.update_all(designation_account_id: nil)
        expect(appeal.contacts_by_opts(['Partner - Financial'], [], increasedGiving3months: true).count).to eq(1)
      end
    end

    def import_giving_info(giving_info)
      Donation.destroy_all
      contact.update(pledge_frequency: giving_info[:pledge_frequency], last_donation_date: nil)

      donations = []
      giving_info[:amounts].reverse.each_with_index do |amount, i|
        next if amount == 0
        donations << build(:donation,
                           donor_account: donor_account,
                           amount: amount, donation_date: Date.today << i,
                           designation_account: da)
      end
      Donation.import(donations)
      contact.update(first_donation_date: donations.map(&:donation_date).min,
                     last_donation_date: donations.map(&:donation_date).max)
    end
  end
end
