require 'async'
require 'charlock_holmes'
require 'csv'

class Import < ApplicationRecord
  include Async
  include Sidekiq::Worker

  sidekiq_options queue: :api_import, retry: 0, backtrace: true, unique: :until_executed
  mount_uploader :file, ImportUploader

  SOURCES = %w(facebook twitter linkedin tnt google tnt_data_sync csv).freeze
  SOURCE_ERROR_MESSAGES = {
    tnt: 'You must specify a TntConnect .xml export file to upload to MPDX.'.freeze,
    csv: 'You must specify a .csv spreadsheet file from to upload to MPDX.'.freeze,
    tnt_data_sync: 'You must specify a TntDataSync (.tntdatasync or .tntmpd) '\
                   'donor export file from your organization to upload to MPDX.'.freeze
  }.freeze
  MAX_FILE_SIZE_IN_BYTES = 500_000_000
  PERMITTED_ATTRIBUTES = [:created_at,
                          :file,
                          :file_constants_mappings,
                          :file_headers_mappings,
                          { groups: [] },
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
                          :id].freeze

  belongs_to :user
  belongs_to :account_list

  validates :source, inclusion: { in: SOURCES }

  validates :file, file_size: { less_than: MAX_FILE_SIZE_IN_BYTES }
  validates :file, upload_extension: { extension: 'xml', message: SOURCE_ERROR_MESSAGES[:tnt] }, if: :source_tnt?
  validates :file, upload_extension: { extension: 'csv', message: SOURCE_ERROR_MESSAGES[:csv] }, if: :source_csv?
  validates :file, upload_extension: { extension: %w(tntmpd tntdatasync), message: SOURCE_ERROR_MESSAGES[:tnt_data_sync] },
                   if: :source_tnt_data_sync?
  validates :file, :file_headers, :file_headers_mappings, :file_row_samples,
            presence: true, if: :source_csv?, unless: :in_preview?

  validates :file_headers, :file_constants, :file_headers_mappings, :file_constants_mappings, class: { is_a: Hash }
  validates :file_row_samples, :file_row_failures, class: { is_a: Array }
  validates :source_account_id, presence: true, if: :source_tnt_data_sync?
  validates_with CsvImportMappingsValidator, if: :source_csv?, unless: :in_preview?
  validates_with FacebookImportValidator, if: :source_facebook?

  serialize :groups, Array
  serialize :group_tags, JSON
  serialize :file_headers, Hash
  serialize :file_constants, Hash
  serialize :file_row_samples, Array
  serialize :file_headers_mappings, Hash
  serialize :file_constants_mappings, Hash
  serialize :file_row_failures, Array

  after_commit :queue_import, on: [:create, :update]

  # Define convenience methods for checking the import source
  SOURCES.each do |source_to_check|
    define_method("source_#{source_to_check}?") { source == source_to_check }
  end

  def queue_import
    return if in_preview? || queued_for_import_at
    update_column(:queued_for_import_at, Time.current) if async_to_queue(sidekiq_queue, :import)
  end

  def user_friendly_source
    case source
    when 'csv'
      source.upcase
    when 'tnt', 'tnt_data_sync'
      source.titleize
    else
      source.humanize
    end
  end

  def file_path
    return unless file.present?
    file.cache_stored_file! unless file.cached?
    file.path
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
    self.file_headers = {}
    self.file_constants = {}
    self.file_row_samples = []
    self.file_row_failures = []
  end

  # Delegate the import process to a decorator class, each import source should have it's own decorator.
  # The import might happen async in other jobs. If it is async we let the decorator handle the callbacks,
  # but if not then we handle the callbacks right here.
  def import
    ImportCallbackHandler.new(self).handle_start
    async = false

    begin
      async = "#{source.camelize}Import".safe_constantize.new(self).import
    rescue StandardError => exception
      exception.is_a?(Import::UnsurprisingImportError) ? Rollbar.info(exception) : Rollbar.error(exception)
      ImportCallbackHandler.new(self).handle_failure(exception: exception)
      false
    else
      ImportCallbackHandler.new(self).handle_success unless async
      true
    end

  rescue StandardError => exception
    Rollbar.error(exception)
    ImportCallbackHandler.new(self).handle_failure(exception: exception) unless async
    false
  ensure
    ImportCallbackHandler.new(self).handle_complete unless async
  end

  class UnsurprisingImportError < StandardError
  end
end
