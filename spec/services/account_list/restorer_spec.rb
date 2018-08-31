require 'rails_helper'

RSpec.describe AccountList::Restorer do
  describe 'initialize' do
    context 'account_list cannot be found' do
      it 'raises an error' do
        expect { described_class.new(SecureRandom.uuid) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.restore' do
    let(:account_list_id) { SecureRandom.uuid }
    it 'calls RowTransferRequest' do
      expect(AccountList::Restorer).to receive(:new).with(account_list_id).and_return(
        OpenStruct.new(
          store: {
            'people' => %w(123 456)
          }
        )
      )
      expect(RowTransferRequest).to receive(:transfer).with('people', %w(123 456))
      described_class.restore(account_list_id)
    end
  end

  describe '#store' do
    before do
      2.times { ApplicationSeeder.new.seed }
    end

    let(:user) { User.order(:created_at).first }
    let(:account_list) { user.account_lists.order(:created_at).first }
    subject { described_class.new(account_list.id).store }

    let!(:records_to_copy) do
      records_to_copy = {}
      [
        account_list,
        account_list.account_list_coaches,
        account_list.account_list_entries,
        account_list.account_list_invites,
        account_list.account_list_users,
        account_list.activities,
        account_list.activities.collect(&:activity_contacts).flatten,
        account_list.activities.collect(&:comments).flatten,
        account_list.activities.collect(&:google_emails).flatten,
        account_list.activities.collect(&:google_email_activities).flatten,
        account_list.activities.collect(&:google_events).flatten,
        account_list.appeals,
        account_list.appeals.collect(&:appeal_contacts).flatten,
        account_list.appeals.collect(&:excluded_appeal_contacts).flatten,
        account_list.companies,
        account_list.company_partnerships,
        account_list.contacts,
        account_list.contacts.collect(&:addresses).flatten,
        account_list.contacts.collect(&:contact_donor_accounts).flatten,
        account_list.contacts.collect(&:contact_notes_logs).flatten,
        account_list.contacts.collect(&:contact_people).flatten,
        account_list.contacts.collect(&:contact_referrals_by_me).flatten,
        account_list.contacts.collect(&:donor_accounts).flatten,
        account_list.contacts.collect(&:partner_status_logs).flatten,
        account_list.designation_accounts,
        account_list.designation_accounts.collect(&:account_list_entries).flatten,
        account_list.designation_accounts.collect(&:balances).flatten,
        account_list.designation_accounts.collect(&:designation_profile_accounts).flatten,
        account_list.designation_accounts.collect(&:donations).flatten,
        account_list.designation_profiles,
        account_list.donations,
        account_list.pledges,
        account_list.pledges.collect(&:pledge_donations).flatten,
        account_list.google_integrations,
        account_list.imports,
        account_list.mail_chimp_account,
        account_list.mail_chimp_account.mail_chimp_appeal_list,
        account_list.mail_chimp_account.mail_chimp_members,
        account_list.notification_preferences,
        account_list.notifications,
        account_list.people,
        account_list.people.collect(&:companies).flatten,
        account_list.people.collect(&:company_positions).flatten,
        account_list.people.collect(&:donor_account_people).flatten,
        account_list.people.collect(&:donor_accounts).flatten,
        account_list.people.collect(&:facebook_accounts).flatten,
        account_list.people.collect(&:family_relationships).flatten,
        account_list.people.collect(&:google_accounts).flatten,
        account_list.people.collect(&:google_contacts).flatten,
        account_list.people.collect(&:key_accounts).flatten,
        account_list.people.collect(&:linkedin_accounts).flatten,
        account_list.people.collect(&:phone_numbers).flatten,
        account_list.people.collect(&:pictures).flatten,
        account_list.people.collect(&:twitter_accounts).flatten,
        account_list.people.collect(&:websites).flatten,
        account_list.people.collect(&:email_addresses).flatten,
        account_list.pls_account,
        account_list.prayer_letters_account,
        account_list.duplicate_record_pairs,
        GooglePlusAccount.where(
          id: account_list.people.joins(email_addresses: [:google_plus_account]).pluck('google_plus_accounts.id')
        ),
        MasterAddress.where(
          id: account_list.contacts.joins(addresses: [:master_address]).pluck('master_addresses.id')
        ),
        MasterCompany.where(
          id: account_list.people.joins(donor_accounts: [:master_company]).pluck('master_companies.id') +
              account_list.contacts.joins(donor_accounts: [:master_company]).pluck('master_companies.id') +
              account_list.companies.joins(:master_company).pluck('master_companies.id')
        ),
        MasterPerson.where(
          id: account_list.people.joins(:master_person).pluck('master_people.id')
        ),
        MasterPersonDonorAccount.where(
          id: account_list.people
                          .joins(donor_accounts: [:master_person_donor_accounts])
                          .pluck('master_person_donor_accounts.id') +
              account_list.contacts
                          .joins(donor_accounts: [:master_person_donor_accounts])
                          .pluck('master_person_donor_accounts.id') +
              account_list.contacts
                          .joins(addresses: [source_donor_account: [:master_person_donor_accounts]])
                          .pluck('master_person_donor_accounts.id')
        ),
        MasterPersonSource.where(
          id: account_list.people
                          .joins(master_person: [:master_person_sources])
                          .pluck('master_person_sources.id')
        ),
        ActsAsTaggableOn::Tag.where(
          id: account_list.contacts.joins(taggings: [:tag]).pluck('tags.id') +
              account_list.activities.joins(taggings: [:tag]).pluck('tags.id')
        ),
        ActsAsTaggableOn::Tagging.where(
          id: account_list.contacts.joins(:taggings).pluck('taggings.id') +
              account_list.activities.joins(:taggings).pluck('taggings.id')
        )
      ].each do |record|
        if record.is_a?(ActiveRecord::Associations::CollectionProxy) ||
           record.is_a?(ActiveRecord::Relation) ||
           record.is_a?(Array)
          next if record.empty?
          table_name = record.first.class.table_name
          ids = record.collect(&:id)
        else
          table_name = record.class.table_name
          ids = [record.id]
        end
        records_to_copy[table_name] ||= []
        records_to_copy[table_name] = (records_to_copy[table_name] + ids).uniq
      end
      records_to_copy
    end

    it 'store includes records associated to the account_list' do
      subject.each do |table_name, ids|
        expect(records_to_copy[table_name]).to match_array ids
      end
    end
  end
end
