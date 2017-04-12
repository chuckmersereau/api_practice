require 'async'
require 'charlock_holmes'
require 'csv'

class Import < ApplicationRecord
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_import, retry: false, backtrace: true, unique: :until_executed
  mount_uploader :file, ImportUploader

  SOURCES = %w(facebook twitter linkedin tnt google tnt_data_sync csv).freeze
  SOURCE_ERROR_MESSAGES = {
    tnt: 'You must specify a TntMPD .xml export file to upload to MPDX (see video linked below for more info).'.freeze,
    csv: 'You must specify a .csv spreadsheet file from to upload to MPDX.'.freeze,
    tnt_data_sync: 'You must specify a TntMPD .tntmpd donor export file from your organization to upload to MPDX.'.freeze
  }.freeze
  MAX_FILE_SIZE_IN_BYTES = 100_000_000
  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :created_at,
                          :file,
                          :file_constants_mappings,
                          :file_headers_mappings,
                          :group_tags,
                          :groups,
                          :import_by_group,
                          :in_preview,
                          :overwrite,
                          :override,
                          :source,
                          :source_account_id,
                          :tag_list,
                          :updated_at,
                          :updated_in_db_at,
                          :user_id,
                          :uuid].freeze

  belongs_to :user
  belongs_to :account_list

  validates :source, inclusion: { in: SOURCES }
  validates :file, file_size: { less_than: MAX_FILE_SIZE_IN_BYTES }
  validates :file, upload_extension: { extension: 'xml',    message: SOURCE_ERROR_MESSAGES[:tnt]           }, if: :source_tnt?
  validates :file, upload_extension: { extension: 'tntmpd', message: SOURCE_ERROR_MESSAGES[:tnt_data_sync] }, if: :source_tnt_data_sync?
  validates :file, upload_extension: { extension: 'csv',    message: SOURCE_ERROR_MESSAGES[:csv]           }, if: :source_csv?
  validates :file, :file_headers, :file_constants, :file_headers_mappings, :file_row_samples, presence: true, if: :source_csv?, unless: :in_preview?
  validates :file_headers, :file_constants, :file_headers_mappings, :file_constants_mappings, class: { is_a: Hash }
  validates :file_row_samples, class: { is_a: Array }
  validates_with CsvImportMappingsValidator, if: :source_csv?, unless: :in_preview?
  validates_with FacebookImportValidator, if: :source_facebook?

  serialize :groups, Array
  serialize :group_tags, JSON
  serialize :file_headers, Hash
  serialize :file_constants, Hash
  serialize :file_row_samples, Array
  serialize :file_headers_mappings, Hash
  serialize :file_constants_mappings, Hash

  after_commit :queue_import

  # Define convenience methods for checking the import source
  SOURCES.each do |source_to_check|
    define_method("source_#{source_to_check}?") { source == source_to_check }
  end

  def queue_import
    async_to_queue(sidekiq_queue, :import) unless in_preview?
  end

  def user_friendly_source
    source.tr('_', ' ')
  end

  def file_contents
    @file_contents ||= read_file_contents
  end

  def file=(new_file)
    reset_file
    super
  end

  # This model handles it's own tags in it's "tags" attribute,
  # tags are persisted as a comma delimited list. We've created
  # accessor methods tag_list and tags to provide consistency
  # with the rest of the app.
  def tags
    attributes['tags'].try(:split, ',')
  end

  def tags=(new_tags)
    super(Array.wrap(new_tags).join(','))
  end

  def tag_list
    attributes['tags']
  end

  def tag_list=(new_tag_list)
    self.tags = new_tag_list.try(:split, ',')
  end

  private

  def sidekiq_queue
    "api_import_#{source}"
  end

  def reset_file
    @file_contents = nil
    self.file_headers = {}
    self.file_constants = {}
    self.file_row_samples = []
  end

  def read_file_contents
    file.cache_stored_file!
    contents = File.open(file.file.file, &:read)
    EncodingUtil.normalized_utf8(contents) || contents
  end

  def import
    import_start_time = Time.current
    update_column(:importing, true)
    "#{source.camelize}Import".constantize.new(self).import
    after_import_success(import_started_at: import_start_time)
    true
  rescue UnsurprisingImportError => exception
    Rollbar.info(exception)
    after_import_failure
    false
  rescue => exception
    Rollbar.error(exception)
    after_import_failure
    raise exception
  ensure
    update_column(:importing, false)
  end

  def after_import_success(import_started_at:)
    begin
      ImportMailer.delay.complete(self)
    rescue => mail_exception
      Rollbar.error(mail_exception)
    end
    account_list.merge_contacts # clean up data
    account_list.queue_sync_with_google_contacts
    account_list.mail_chimp_account.queue_export_to_primary_list if account_list.valid_mail_chimp_account
    Contact::SuggestedChangesUpdaterWorker.perform_async(user.id, import_started_at)
  end

  def after_import_failure
    ImportMailer.delay.failed(self)
  rescue => mail_exception
    Rollbar.error(mail_exception)
  end

  class UnsurprisingImportError < StandardError
  end
end
