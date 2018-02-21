require 'rails_helper'
require Rails.root.join('db/seeders/application_seeder')

RSpec.describe AccountList::Destroyer do
  let(:user) { User.order(:created_at).first }
  let(:account_list) { user.account_lists.first }
  let(:destroyer) { AccountList::Destroyer.new(account_list.id) }

  before do
    2.times { ApplicationSeeder.new.seed }
  end

  describe 'initialize' do
    subject { AccountList::Destroyer.new(account_list.id) }

    it 'initializes' do
      expect(subject).to be_a(AccountList::Destroyer)
    end

    context 'account_list cannot be found' do
      before do
        account_list.delete
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#destroy!' do
    subject { destroyer.destroy! }

    let(:records_to_delete) do
      [
        account_list,
        account_list.account_list_coaches,
        account_list.account_list_entries,
        account_list.account_list_invites,
        account_list.account_list_users,
        account_list.activities,
        account_list.activities.collect(&:activity_contacts).flatten,
        account_list.activities.collect(&:comments).flatten,
        account_list.activities.collect(&:google_email_activities).flatten,
        account_list.appeals,
        account_list.appeals.collect(&:appeal_contacts).flatten,
        account_list.appeals.collect(&:excluded_appeal_contacts).flatten,
        account_list.company_partnerships,
        account_list.contacts,
        account_list.contacts.collect(&:contact_donor_accounts).flatten,
        account_list.contacts.collect(&:contact_people).flatten,
        account_list.contacts.collect(&:contact_referrals_by_me).flatten,
        account_list.contacts.collect(&:addresses).flatten,
        account_list.designation_accounts,
        account_list.designation_accounts.collect(&:account_list_entries).flatten,
        account_list.designation_accounts.collect(&:balances).flatten,
        account_list.designation_accounts.collect(&:designation_profile_accounts).flatten,
        account_list.designation_accounts.collect(&:donations).flatten,
        account_list.designation_profiles,
        account_list.donations,
        account_list.google_integrations,
        account_list.imports,
        account_list.mail_chimp_account,
        account_list.mail_chimp_account.mail_chimp_appeal_list,
        account_list.mail_chimp_account.mail_chimp_members,
        account_list.notification_preferences,
        account_list.notifications,
        account_list.people,
        account_list.people.collect(&:company_positions).flatten,
        account_list.people.collect(&:facebook_accounts).flatten,
        account_list.people.collect(&:family_relationships).flatten,
        account_list.people.collect(&:google_accounts).flatten,
        account_list.people.collect(&:key_accounts).flatten,
        account_list.people.collect(&:linkedin_accounts).flatten,
        account_list.people.collect(&:phone_numbers).flatten,
        account_list.people.collect(&:pictures).flatten,
        account_list.people.collect(&:relay_accounts).flatten,
        account_list.people.collect(&:twitter_accounts).flatten,
        account_list.people.collect(&:websites).flatten,
        account_list.people.collect(&:email_addresses).flatten,
        account_list.pls_account,
        account_list.prayer_letters_account,
        account_list.duplicate_record_pairs
      ].collect(&:presence).flatten.collect do |record|
        record.is_a?(ActiveRecord::Associations::CollectionProxy) ? record.to_a.presence : record.presence
      end.flatten
    end

    let(:records_to_leave_alone) do
      (ApplicationRecord.descendants - [User, User::Coach, DonationAmountRecommendation::Remote]).collect do |klass|
        klass.all.to_a.presence
      end.flatten - records_to_delete
    end

    it 'deletes the account list and associated records' do
      expect(records_to_delete.all? { |record| record.class.exists?(record.id) }).to eq(true)
      subject
      records_not_deleted = records_to_delete.select { |record| record.class.exists?(record.id) }
      expect(records_not_deleted).to eq([])
    end

    it 'does not delete records not associated to the account list' do
      expect(records_to_leave_alone.all? { |record| record.class.exists?(record.id) }).to eq(true)
      subject
      records_deleted = records_to_leave_alone.select { |record| !record.class.exists?(record.id) }
      expect(records_deleted).to eq([])
    end
  end
end
