require 'rails_helper'

describe TntImport::GiftsImport do
  before do
    stub_smarty_streets
  end

  context '#import gifts for offline orgs' do
    before do
      stub_request(:post, 'http://foo:bar@example.com/profiles')
        .with(body: { 'Action' => 'Profiles', 'Password' => 'Test1234', 'UserName' => 'test@test.com' })
        .to_return(body: '')

      @account_list = create(:account_list)
      @offline_org = create(:offline_org)
      @user = create(:user)
      @user.organization_accounts << create(:organization_account, organization: @offline_org)
      @account_list.users << @user

      @import = create(:tnt_import_gifts, account_list: @account_list)
      @tnt_import = TntImport.new(@import)
      @import_with_personal_gift = create(:tnt_import_with_personal_gift, account_list: @account_list)
      @tnt_import_with_personal_gift = TntImport.new(@import_with_personal_gift)
      @appeal = create(:appeal, account_list: @account_list, tnt_id: '1')
      @second_appeal = create(:appeal, account_list: @account_list, tnt_id: '2')
    end

    let(:setup_online_org) do
      @user.organization_accounts.destroy_all
      online_org = create(:organization)
      @user.organization_accounts << create(:organization_account, organization: online_org)
    end

    let(:donation_generated_with_gift_splits) { Appeal.find_by(tnt_id: 2).donations.first }

    it 'handles an xml that has no gifts' do
      @import = create(:tnt_import_no_gifts, account_list: @account_list)
      @tnt_import = TntImport.new(@import)
      expect { @tnt_import.import }.to_not change(Donation, :count).from(0)
    end

    it 'does import gifts for an online org when gift is marked as personal' do
      setup_online_org
      expect { @tnt_import_with_personal_gift.import }.to change(Donation, :count).from(0).to(2)
    end

    it 'links gifts to first appeal and adds other gift splits to memo' do
      setup_online_org
      @tnt_import_with_personal_gift.import
      expect(donation_generated_with_gift_splits.appeal).to eq(@second_appeal)
      expect(donation_generated_with_gift_splits.memo).to eq(
        %(This donation was imported from Tnt.\n\n$841 is designated to the "#{@appeal.name}" appeal.)
      )
    end

    it 'does not import gifts for an online org or multiple orgs when gift not marked as personal' do
      @user.organization_accounts.destroy_all
      online_org = create(:organization)
      @user.organization_accounts << create(:organization_account, organization: online_org)

      expect { @tnt_import.import }.to_not change(Donation, :count).from(0)

      @user.organization_accounts.destroy_all
      @user.organization_accounts << create(:organization_account, organization: @offline_org)
      @user.organization_accounts << create(:organization_account, organization: create(:offline_org))
      expect { @tnt_import.import  }.to_not change(Donation, :count).from(0)
    end

    it 'imports gifts for a single offline org' do
      expect { @tnt_import.import  }.to change(Donation, :count).from(0).to(2)
      contact = Contact.first
      fields = [:donation_date, :amount, :tendered_amount, :tendered_currency]
      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(*fields) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50,
                                   tendered_amount: 50, tendered_currency: 'USD')
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25,
                                   tendered_amount: 25, tendered_currency: 'USD')

      expect(contact.last_donation_date).to eq(Date.new(2013, 11, 21))
      expect(contact.first_donation_date).to eq(Date.new(2013, 11, 20))
      expect(contact.total_donations).to eq(75.0)

      expect(contact.donor_accounts.count).to eq(1)
      donor_account = contact.donor_accounts.first
      expect(donor_account.total_donations).to eq(75.0)
      expect(donor_account.name).to eq('Test, Dave')
    end

    it 'finds a unique donor number for new contacts' do
      # Make sure it does a numeric search not an alphabetic one to find 10 as the max and not 9.
      @offline_org.donor_accounts.create(account_number: '10')
      @offline_org.donor_accounts.create(account_number: '9')
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      Donation.all.each do |donation|
        expect(donation.donor_account.account_number).to eq('11')
      end
    end

    it 'does not re-import the same gifts multiple times but adds new gifts in existing donor accounts' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)

      expect(DonorAccount.first.account_number).to eq('1')

      import2 = create(:tnt_import_gifts_added, account_list: @account_list, user: @import.user)
      tnt_import2 = TntImport.new(import2)

      expect { tnt_import2.import  }.to change(Donation, :count).from(2).to(3)

      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(:donation_date, :amount, :memo) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50, memo: 'This donation was imported from Tnt.')
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25, memo: 'This donation was imported from Tnt.')
      expect(donations).to include(donation_date: Date.new(2013, 11, 22), amount: 100, memo: 'This donation was imported from Tnt.')

      contact = Contact.first
      expect(contact.last_donation_date).to eq(Date.new(2013, 11, 22))
      expect(contact.first_donation_date).to eq(Date.new(2013, 11, 20))
      expect(contact.total_donations).to eq(175.0)

      expect(contact.donor_accounts.count).to eq(1)
      donor_account = contact.donor_accounts.first
      expect(donor_account.account_number).to eq('1')
      expect(donor_account.total_donations).to eq(175.0)
    end

    it 'assigns the gift currency code' do
      @user.organization_accounts.destroy_all
      online_org = create(:organization)
      @user.organization_accounts << create(:organization_account, organization: online_org)
      @tnt_import_with_personal_gift.import
      expect(Donation.exists?(tendered_amount: 50, tendered_currency: 'CAD')).to eq(true)
      expect(Donation.exists?(tendered_amount: 25, tendered_currency: 'USD')).to eq(true)
    end

    it 'assigns a designation account to each donation' do
      expect { @tnt_import.import }.to change { Donation.count }.from(0)
      Donation.all.each do |donation|
        expect(donation.designation_account.present?).to eq(true)
      end
    end

    it 'does not recreate the designation account when re-importing' do
      expect { @tnt_import.import }.to change { @account_list.designation_accounts.reload.count }.from(0).to(1)
      Donation.destroy_all
      expect { @tnt_import.import }.to_not change { @account_list.designation_accounts.reload.count }.from(1)
    end

    it 'creates a designation account' do
      expect { @tnt_import.import }.to change { @account_list.designation_accounts.reload.count }.from(0).to(1)
      designation_account = @account_list.designation_accounts.last
      expect(designation_account.name).to eq("#{@import.user.to_s.strip} (Imported from TntConnect)")
      expect(designation_account.organization).to eq(@offline_org)
    end

    it 'reimports the designation account' do
      expect { @tnt_import.import }.to change { @account_list.designation_accounts.reload.count }.from(0).to(1)
      first_designation_account_id = @account_list.designation_accounts.first.id
      donation = @account_list.donations.first
      DesignationAccount.delete_all
      expect { @tnt_import.import }.to change { donation.reload.designation_account_id }.from(first_designation_account_id)
    end
  end
end
