class QueueContactDupMergeBatchWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_contact_dup_contacts_merge_worker

  def perform(account_list_id, since_unix_time)
    @account_list = AccountList.find_by_id(account_list_id)
    return true unless @account_list
    @since_time = Time.at(since_unix_time)
    queue_batch_jobs
    batch.bid
  end

  private

  attr_reader :account_list, :since_time

  def batch
    return @batch if @batch
    @batch = Sidekiq::Batch.new
    @batch.description = "Merge duplicate Contacts for AccountList #{account_list.id} since #{since_time.utc}"
    @batch
  end

  # If we run a merge on two duplicate contacts at the same time in parallel then it can result in both contacts being deleted.
  # To avoid that we check for duplicates here and avoid queuing merge jobs for them.
  def queue_batch_jobs
    batch.jobs do
      queued_ids = []
      contacts.each do |contact|
        contact_ids_to_merge = duplicates_ids_for_contact(contact) << contact.id
        next if (queued_ids & contact_ids_to_merge).present?
        queued_ids += contact_ids_to_merge
        ContactDupMergeWorker.perform_async(account_list.id, contact.id)
      end
    end
  end

  def contacts
    account_list.contacts.where('updated_at >= ?', since_time)
  end

  def duplicates_ids_for_contact(contact)
    Contact::DupContactsMerge.new(account_list: account_list, contact: contact).find_duplicates.collect(&:id)
  end
end
