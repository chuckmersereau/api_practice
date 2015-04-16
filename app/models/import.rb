require 'async'

class Import < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :import, retry: false, backtrace: true, unique: true

  belongs_to :user
  mount_uploader :file, ImportUploader
  belongs_to :account_list

  validates :source, inclusion: { in: %w(facebook twitter linkedin tnt google tnt_data_sync) }
  TNT_MSG = 'You must specify a TntMPD .xml export file to upload to MPDX (see video linked below for more info).'
  validates :file, if: ->(import) { 'tnt' == import.source }, upload_extension: { extension: 'xml', message: TNT_MSG }
  TNT_DATA_SYNC_MSG = 'You must specify a TntMPD .tntmpd donor export file from your organization to upload to MPDX.'
  validates :file, if: ->(import) { 'tnt_data_sync' == import.source }, upload_extension: { extension: 'tntmpd', message: TNT_DATA_SYNC_MSG }
  validates_with FacebookImportValidator, if: -> (import) { 'facebook' == import.source }

  serialize :groups, Array
  serialize :group_tags, JSON

  after_commit :queue_import

  def queue_import
    async(:import)
  end

  def user_friendly_source
    source.gsub('_', ' ')
  end

  private

  def import
    update_column(:importing, true)
    begin
      "#{source.camelize}Import".constantize.new(self).import
      ImportMailer.complete(self).deliver

      account_list.merge_contacts # clean up data
      account_list.queue_sync_with_google_contacts
      true
    rescue UnsurprisingImportError
      # Only send a failure email, don't re-raise the error, as it was not considered a surprising error by the
      # import function, so don't re-raise it (that will prevent non-surprising errors from being logged via Airbrake).
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
