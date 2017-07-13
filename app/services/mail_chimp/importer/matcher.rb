# This class finds MPDX People matching the member_info objects from MailChimp.
class MailChimp::Importer
  class Matcher
    attr_reader :mail_chimp_account, :account_list

    def initialize(mail_chimp_account)
      @mail_chimp_account = mail_chimp_account
      @account_list = mail_chimp_account.account_list
    end

    def find_matching_people(member_infos)
      people_matching_member_infos = fetch_people_matching_member_infos(member_infos)
      reject_extra_subscribe_causers(people_matching_member_infos)
    end

    private

    def fetch_people_matching_member_infos(member_infos)
      member_infos.each_with_object({}.with_indifferent_access) do |member_info, matching_people_hash|
        person = find_person(member_info[:first_name], member_info[:last_name], member_info[:email])

        matching_people_hash[person.id] ||= member_info if person
      end
    end

    def find_person(first_name, last_name, email)
      person_by_email(email) || person_by_name(first_name, last_name)
    end

    def person_by_name(first_name, last_name)
      account_list.people.find_by(first_name: first_name, last_name: last_name)
    end

    def person_by_email(email)
      account_list.people.joins(:primary_email_address)
                  .find_by(email_addresses: { email: email })
    end

    def reject_extra_subscribe_causers(people_matching_member_infos)
      contacts_associated_to_person_ids = fetch_contacts_associated_to_person_ids(people_matching_member_infos.keys)

      contacts_that_should_be_imported = contacts_associated_to_person_ids.select do |contact|
        contact_that_should_be_imported?(contact, people_matching_member_infos)
      end

      people_matching_member_infos.slice(*contacts_that_should_be_imported.flat_map(&:people).map(&:id))
    end

    def fetch_contacts_associated_to_person_ids(person_ids)
      account_list.contacts
                  .joins(:people)
                  .where(people: { id: person_ids })
    end

    def contact_that_should_be_imported?(contact, people_matching_member_infos)
      return true if contact.send_newsletter.in?(%w(Email Both))

      contact.people.all? do |person|
        person_should_be_imported?(person, people_matching_member_infos)
      end
    end

    def person_should_be_imported?(person, people_matching_member_infos)
      person.primary_email_address.blank? ||
        person.optout_enewsletter? ||
        people_matching_member_infos.include?(person.id)
    end
  end
end
