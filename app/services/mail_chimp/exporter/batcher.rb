# This class handles all batch operations used when communicating with the MailChimp API.
class MailChimp::Exporter
  class Batcher
    attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

    delegate :email_hash, to: :mail_chimp_account

    def initialize(mail_chimp_account, gibbon_wrapper, list_id, appeal = nil)
      @mail_chimp_account = mail_chimp_account
      @gibbon_wrapper = gibbon_wrapper
      @list_id = list_id
      @appeal = appeal
    end

    def subscribe_contacts(contacts)
      members_params = fetch_member_params_from_contacts(contacts).uniq

      batch_create_members(members_params)
      create_member_records(members_params)
    end

    def unsubscribe_members(emails_with_reasons)
      return if emails_with_reasons.none?

      operations = emails_with_reasons.map do |email, reason|
        [unsubscribe_operation(email), note_reason_operation(email, reason)]
      end.flatten.compact

      send_batch_operations(operations)
      delete_member_records(emails_with_reasons.keys)
    end

    def unsubscribe_operation(email)
      {
        method: 'PATCH',
        path: "/lists/#{list_id}/members/#{email_hash(email)}",
        body: { status: 'unsubscribed' }.to_json
      }
    end

    def note_reason_operation(email, reason)
      return unless reason.present?
      {
        method: 'POST',
        path: "/lists/#{list_id}/members/#{email_hash(email)}/notes",
        body: { note: "Unsubscribed by MPDX: #{reason}" }.to_json
      }
    end

    def fetch_member_params_from_contacts(contacts)
      relevant_people = Person.joins(:contact_people, :primary_email_address)
                              .where(contact_people: { contact: contacts })
                              .preload(:contact_people, :primary_email_address)

      contacts.each_with_object([]) do |contact, members_params|
        people_that_belong_to_contact(relevant_people, contact).each do |person|
          next if person.optout_enewsletter?

          members_params << person_to_member_param(person, contact)
        end
      end
    end

    def people_that_belong_to_contact(people, contact)
      people.select do |person|
        person_belongs_to_contact?(person, contact)
      end
    end

    def person_belongs_to_contact?(person, contact)
      person.contact_people.map(&:contact_id).each do |contact_id|
        return true if contact_id == contact.id
      end

      false
    end

    def person_to_member_param(person, contact)
      member_params = fetch_base_member_params(person, contact)

      member_params[:merge_fields].merge(DONATED_TO_APPEAL: @appeal.donated?(contact)) if appeal_export?

      member_params[:language] = contact.locale if contact.locale.present?

      add_status_and_tags_groupings_to_params(contact, member_params)
    end

    def add_status_and_tags_groupings_to_params(contact, member_params)
      member_params[:interests] = member_params[:interests].to_h
      member_params[:interests].merge!(interests_for_status(contact.status))
      member_params[:interests].merge!(interests_for_tags(contact.tag_list))
      member_params
    end

    def fetch_base_member_params(person, contact)
      return unless person.primary_email_address

      {
        status: 'subscribed',
        email_address: person.primary_email_address.email,
        merge_fields: {
          EMAIL: person.primary_email_address.email, FNAME: person.first_name,
          LNAME: person.last_name || '', GREETING: contact.greeting
        }
      }
    end

    def batch_create_members(members_params)
      operations = members_params.map do |member_params|
        {
          method: 'PUT',
          path: "/lists/#{list_id}/members/#{email_hash(member_params[:email_address])}",
          body: member_params.to_json
        }
      end

      send_batch_operations(operations)
    end

    def send_batch_operations(operations)
      # MailChimp is giving a weird error every once in a while.
      # At first glance it seems to be a Bad Request Error, however the
      # legitimate Bad Request error message is different. Because I've never
      # seen this happen more than twice in a row, I think that this solution
      # will do.
      groups_with_batches = operations.in_groups_of(50, false).map do |group_of_operations|
        escape_intermittent_bad_request_error do
          batch = gibbon_wrapper.batches.create(body: { operations: group_of_operations })
          { batch: batch, operations: group_of_operations }
        end
      end
      groups_with_batches.each(&method(:log_batches))
    end

    def log_batches(group_with_batch)
      batch = group_with_batch[:batch]
      self_link = batch['_links'].find { |link| link['rel'] == 'self' }.try(:[], 'href')
      group_with_batch[:operations].each do |operation|
        AuditChangeWorker.perform_async(
          created_at: Time.zone.now,
          action: 'create',
          auditable_type: 'MailChimpBatch',
          audtiable_id: batch['id'],
          audited_changes: operation.to_json,
          associated_id: mail_chimp_account.id,
          associated_type: 'MailChimpAccount',
          comment: self_link
        )
      end
      MailChimp::BatchResultsWorker.perform_in(15.minutes, mail_chimp_account.id, batch['id'])
    end

    def escape_intermittent_bad_request_error
      retry_count ||= 0

      yield
    rescue Gibbon::MailChimpError => error

      raise unless intermittent_error?(error)

      sleep 10 if too_many_batches_error?(error)
      # If the MC API responds with the 'too many batches opened' error,
      # we wait for 10 seconds hoping that other batches will complete in that time.

      raise if (retry_count += 1) >= 5

      retry
    end

    def intermittent_error?(error)
      intermittent_bad_request_error?(error) ||
        intermittent_nesting_too_deep_error?(error) ||
        too_many_batches_error?(error)
    end

    def too_many_batches_error?(error)
      error.message.include?('You have more than 500 pending batches.')
    end

    def intermittent_nesting_too_deep_error?(error)
      error.message.include?('nested too deeply')
    end

    def intermittent_bad_request_error?(error)
      error.message.include?('<H1>Bad Request</H1>')
    end

    def create_member_records(members_params)
      members_params.each do |member_params|
        member = mail_chimp_account.mail_chimp_members.find_or_create_by(list_id: list_id,
                                                                         email: member_params[:email_address])

        member.update(first_name: member_params[:merge_fields][:FNAME],
                      greeting: member_params[:merge_fields][:GREETING],
                      last_name: member_params[:merge_fields][:LNAME],
                      status: status_for_interest_ids(member_params[:interests]),
                      tags: tags_for_interest_ids(member_params[:interests]))
      end
    end

    def delete_member_records(emails)
      MailChimpMember.where('lower(email) in (?)', emails)
                     .where(list_id: list_id, mail_chimp_account_id: mail_chimp_account.id)
                     .each(&:destroy)
    end

    def interests_for_tags(tags)
      Hash[cached_interest_ids(:tags).map do |tag, interest_id|
        [interest_id, tags.include?(tag)]
      end]
    end

    def interests_for_status(contact_status)
      Hash[cached_interest_ids(:statuses).map do |status, interest_id|
        [interest_id, status == _(contact_status)]
      end]
    end

    def tags_for_interest_ids(interests)
      mail_chimp_account.tags_interest_ids_for_list(list_id).invert.values_at(
        fetch_interest_ids(:tags, interests).first
      ) if interests.present?
    end

    def status_for_interest_ids(interests)
      mail_chimp_account.statuses_interest_ids_for_list(list_id).invert[
        fetch_interest_ids(:statuses, interests).first
      ] if interests.present?
    end

    def fetch_interest_ids(attribute, interests)
      cached_interest_ids(attribute).values &
        interests.select { |_, value| value.present? }.keys
    end

    def cached_interest_ids(attribute)
      InterestIdsCacher.new(mail_chimp_account, gibbon_wrapper, list_id).cached_interest_ids(attribute)
    end

    def appeal_export?
      @appeal
    end

    def gibbon_list
      gibbon_wrapper.gibbon_list_object(list_id)
    end
  end
end
