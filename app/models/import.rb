require 'async'
require 'charlock_holmes'
require 'csv'

class Import < ApplicationRecord
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false, backtrace: true, unique: :until_executed
  mount_uploader :file, ImportUploader

  SOURCES = %w(facebook twitter linkedin tnt google tnt_data_sync csv).freeze
  SOURCE_ERROR_MESSAGES = {
    tnt: 'You must specify a TntMPD .xml export file to upload to MPDX (see video linked below for more info).'.freeze,
    csv: 'You must specify a .csv spreadsheet file from to upload to MPDX.'.freeze,
    tnt_data_sync: 'You must specify a TntMPD .tntmpd donor export file from your organization to upload to MPDX.'.freeze
  }.freeze
  MAX_FILE_SIZE_IN_BYTES = 10_000_000
  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :created_at,
                          :file,
                          :file_constants_mappings,
                          :file_headers_mappings,
                          :group_tags,
                          :groups,
                          :import_by_group,
                          :in_preview,
                          :override,
                          :source,
                          :source_account_id,
                          :tags,
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
    async(:import) unless in_preview?
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

  private

  def reset_file
    @file_contents = nil
    self.file_headers = {}
    self.file_constants = {}
    self.file_row_samples = []
  end

  def read_file_contents
    file.cache_stored_file!
    contents = File.open(file.file.file, &:read)
    EncodingUtil.normalized_utf8(contents)
  end

  def import
    update_column(:importing, true)
    begin
      "#{source.camelize}Import".constantize.new(self).import
      ImportMailer.complete(self).deliver

      account_list.merge_contacts # clean up data
      account_list.queue_sync_with_google_contacts
      account_list.mail_chimp_account.queue_export_to_primary_list if account_list.valid_mail_chimp_account
      true
    rescue UnsurprisingImportError
      # Only send a failure email, don't re-raise the error, as it was not considered a surprising error by the
      # import function, so don't re-raise it (that will prevent non-surprising errors from being logged via Rollbar).
      ImportMailer.failed(self).deliver
    rescue => e
      ImportMailer.failed(self).deliver
      raise e
    end
  ensure
    update_column(:importing, false)
  end

  class UnsurprisingImportError < StandardError
  end
end
