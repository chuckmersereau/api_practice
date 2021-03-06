require 'rspec_doc_combiner'

namespace :mpdx do
  task set_special: :environment do
    AccountList.find_each do |al|
      al.contacts.includes(:donor_accounts).where.not(donor_accounts: { id: nil }).find_each do |contact|
        contact.update_attributes(status: 'Partner - Special') if contact.status.blank?
      end
    end
  end

  task merge_contacts: :environment do
    AccountList.where('id > 125').find_each do |al|
      puts al.id
      al.async_merge_contacts(1.year.ago)
    end
  end

  task merge_accounts: :environment do
    def merge_account_lists
      AccountList.order('created_at').each do |al|
        other_list = AccountList.where(name: al.name).where("id <> #{al.id} AND name like 'Staff Account (%'").first
        next unless other_list # && other_contact.donor_accounts.first == contact.donor_accounts.first
        puts other_list.name
        al.merge(other_list)
        al.async_merge_contacts(1.year.ago)
        merge_account_lists
        break
      end
    end

    merge_account_lists
  end

  task merge_donor_accounts: :environment do
    def merge_donor_accounts
      account_numbers_query =
        <<~HEREDOC
          select account_number, organization_id from donor_accounts
          where account_number <> ''
          group by account_number, organization_id
          having count(*) > 1
        HEREDOC
      account_numbers = DonorAccount.connection.select_values(account_numbers_query)
      DonorAccount.where(account_number: account_numbers).order('created_at').each do |al|
        other_account = DonorAccount.where(account_number: al.account_number, organization_id: al.organization_id)
                                    .where.not(id: al.id)
                                    .first
        next unless other_account
        puts other_account.account_number
        al.merge(other_account)
        merge_donor_accounts
        break
      end
    end

    merge_donor_accounts
  end

  task address_cleanup: :environment do
    us_address = [nil, '', 'United States', 'United States of America']
    Contact.joins(:addresses)
           .where.not(addresses: { id: nil })
           .where(addresses: { country: us_address })
           .find_each(&:merge_addresses)
  end

  task address_primary_fixes: :environment do
    Contact.find_each do |contact|
      puts "Primary address fix for contact: #{contact.id}"
      contact.addresses_including_deleted.where(deleted: true).update_all(primary_mailing_address: false)
      contact.addresses.where(historic: true).update_all(primary_mailing_address: false)
      next unless contact.addresses.where(historic: false).count == 1
      next unless contact.addresses.where(primary_mailing_address: true).count.zero?
      contact.addresses.first.update_column(:primary_mailing_address, true)
    end
  end

  task clear_stalled_downloads: :environment do
    Person::OrganizationAccount.clear_stalled_downloads
  end

  task timezones: :environment do
    us_address = [nil, '', 'United States', 'United States of America']
    us_contacts = Contact.joins(addresses: :master_address)
                         .preload(addresses: :master_address)
                         .where.not(master_addresses: { id: nil })
                         .where(master_addresses: { country: us_address })
    us_contacts.find_each do |c|
      addresses = c.addresses

      # Find the contact's home address, or grab primary/first address
      address = addresses.find { |a| a.location == 'Home' } ||
                addresses.find(&:primary_mailing_address?) ||
                addresses.first

      # Make sure we have a smarty streets response on file
      next unless address&.master_address && address.master_address.smarty_response.present?

      smarty = address.master_address.smarty_response
      meta = smarty.first['metadata']

      # Convert the smarty time zone to a rails time zone
      zone = ActiveSupport::TimeZone.us_zones.find do |tz|
        tz.tzinfo.current_period.offset.utc_offset / 3600 == meta['utc_offset']
      end

      next unless zone

      # The result of the join above was a read-only record
      contact = Contact.find(c.id)
      contact.update_column(:timezone, zone.name)
    end
  end

  desc 'Generate Docs from Specs'
  task generate_docs: :environment do
    Rake::Task['docs:generate:ordered'].invoke
    RSpecDocCombiner.combine!
  end
end
