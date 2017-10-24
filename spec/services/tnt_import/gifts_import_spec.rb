require 'rails_helper'

describe TntImport::GiftsImport do
  before do
    stub_smarty_streets
  end

  context '#import gifts for offline orgs' do
    before do
      stub_request(:post, 'http://example.com/profiles')
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

    it 'handles an xml that has no gifts' do
      @import = create(:tnt_import_no_gifts, account_list: @account_list)
      @tnt_import = TntImport.new(@import)
      expect { @tnt_import.import }.to_not change(Donation, :count).from(0)
    end

    it 'does import gifts for an online org when gift is marked as personal' do
      setup_online_org
      expect { @tnt_import_with_personal_gift.import }.to change(Donation, :count).from(0).to(2)
    end

    describe 'associating gifts to appeals' do
      context 'version 3.1 and lower' do
        it 'links gifts to first appeal and adds other gift splits to memo' do
          setup_online_org
          @tnt_import.import
          donation = Appeal.find_by(tnt_id: 2).donations.first
          expect(donation.appeal).to eq(@second_appeal)
          expect(donation.memo).to eq('This donation was imported from Tnt.')
        end
      end

      context 'version 3.2 and higher' do
        it 'links gifts to first appeal and adds other gift splits to memo' do
          setup_online_org
          @tnt_import_with_personal_gift.import
          donation = Appeal.find_by(tnt_id: 2).donations.first
          expect(donation.appeal).to eq(@second_appeal)
          expect(donation.memo).to eq(
            %(This donation was imported from Tnt.\n\n$841 is designated to the "#{@appeal.name}" appeal.)
          )
        end
      end
    end

    it 'does not import gifts when the user has multiple orgs' do
      @user.organization_accounts.destroy_all
      @user.organization_accounts << create(:organization_account, organization: @offline_org)
      @user.organization_accounts << create(:organization_account, organization: create(:offline_org))
      expect { @tnt_import.import  }.to_not change(Donation, :count).from(0)
    end

    it 'imports gifts for a single org' do
      expect { @tnt_import.import  }.to change(Donation, :count).from(0).to(2)
      contact = Contact.first
      fields = [:donation_date, :amount, :tendered_amount, :tendered_currency, :tnt_id]
      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(*fields) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50,
                                   tendered_amount: 50, tendered_currency: 'USD', tnt_id: '1-M84S3J')
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25,
                                   tendered_amount: 25, tendered_currency: 'USD', tnt_id: '1-O73R2P')

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

      donations = Donation.all.map { |d| d.attributes.symbolize_keys.slice(:donation_date, :amount, :memo, :tnt_id) }
      expect(donations).to include(donation_date: Date.new(2013, 11, 20), amount: 50, memo: 'This donation was imported from Tnt.', tnt_id: '1-M84S3J')
      expect(donations).to include(donation_date: Date.new(2013, 11, 21), amount: 25, memo: 'This donation was imported from Tnt.', tnt_id: '1-O73R2P')
      expect(donations).to include(donation_date: Date.new(2013, 11, 22), amount: 100, memo: 'This donation was imported from Tnt.', tnt_id: nil)

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

    it 'does not assign a remote_id when creating a donation' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      expect(Donation.where(remote_id: nil).count).to eq(2)
    end

    it 'updates an existing donation by remote_id' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      Donation.where(tnt_id: '1-M84S3J').first.update!(tnt_id: nil, remote_id: '1-M84S3J', amount: 1)
      expect { @tnt_import.import }.to_not change(Donation, :count).from(2)
      expect(Donation.where(tnt_id: '1-M84S3J', remote_id: '1-M84S3J').first.amount).to eq(50.0)
      expect(Donation.where(tnt_id: '1-M84S3J').count).to eq(1)
    end

    it 'updates an existing donation by tnt_id' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      Donation.where(tnt_id: '1-M84S3J').first.update!(remote_id: nil, amount: 1)
      expect { @tnt_import.import }.to_not change(Donation, :count).from(2)
      expect(Donation.where(tnt_id: '1-M84S3J').first.amount).to eq(50.0)
      expect(Donation.where(tnt_id: '1-M84S3J').count).to eq(1)
    end

    it 'updates an existing donation by donor, amount, and date, if there is no tnt_id or remote_id' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      # Set the tnt_id and remote_id to nil, to force the import to find by donor, amount, and date.
      Donation.update_all(tnt_id: nil, remote_id: nil)
      expect { @tnt_import.import }.to_not change(Donation, :count).from(2)
    end

    it 'creates new donations by donor, amount, and date, if there is no tnt_id or remote_id' do
      expect { @tnt_import.import }.to change(Donation, :count).from(0).to(2)
      # Set the tnt_id and remote_id to nil, to force the import to find by donor, amount, and date.
      # Set the amount to 1, to test that the import doesn't find the donation and creates a new one.
      Donation.where(tnt_id: '1-M84S3J').first.update!(tnt_id: nil, remote_id: nil, amount: 1)
      expect { @tnt_import.import }.to change(Donation, :count).from(2).to(3)
      Donation.where(tnt_id: '1-M84S3J').first.update!(tnt_id: nil, remote_id: nil, donor_account_id: create(:donor_account).id)
      expect { @tnt_import.import }.to change(Donation, :count).from(3).to(4)
      Donation.where(tnt_id: '1-M84S3J').first.update!(tnt_id: nil, remote_id: nil, donation_date: Time.current)
      expect { @tnt_import.import }.to change(Donation, :count).from(4).to(5)
    end

    it 'imports multiple donations that were made on the same day, by the same donor, and of the same amount' do
      import = create(:tnt_import_gifts_multiple_same_day, account_list: @account_list, user: @import.user)
      tnt_import = TntImport.new(import)
      expect { tnt_import.import }.to change { Donation.count }.from(0).to(3)
      expect { tnt_import.import }.to_not change { Donation.count }.from(3)
    end

    it 'uses an existing designation_account if it exists' do
      expect { @tnt_import.import }.to change { Donation.count }.from(0).to(2)
      donation = Donation.first
      designation_account = create(:designation_account)
      @account_list.designation_accounts << designation_account
      donation.update!(designation_account: designation_account)
      expect { @tnt_import.import }.to_not change { donation.reload.designation_account }.from(designation_account)
    end

    describe 'creating pledges' do
      it 'creates a pledge if the donation belongs to an appeal' do
        setup_online_org
        expect { @tnt_import_with_personal_gift.import }.to change { Pledge.count }.from(0).to(1)
          .and change { Donation.count }.from(0).to(2)
        pledge = Pledge.first
        donation = pledge.donations.first
        expect(pledge.amount).to eq(25)
        expect(pledge.amount_currency).to eq('USD')
        expect(pledge.expected_date.to_date).to eq(donation.donation_date.to_date)
        expect(pledge.contact).to eq(donation.donor_account.contacts.first)
        expect(donation.appeal).to eq(@second_appeal)
      end

      it 'does not create a pledge if the donation does not belong to an appeal' do
        @import = create(:tnt_import_gifts_without_appeal, account_list: @account_list)
        @tnt_import = TntImport.new(@import)
        setup_online_org
        expect { @tnt_import.import }.to change { Donation.count }.from(0).to(2)
        expect(Pledge.count).to eq(0)
      end

      it 'does not create a new pledge if one already exists' do
        setup_online_org
        expect { @tnt_import_with_personal_gift.import }.to change { Pledge.count }.from(0).to(1)
        expect { @tnt_import_with_personal_gift.import }.to_not change { Pledge.count }.from(1)
      end
    end
  end
end
