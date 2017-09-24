class BackgroundBatch < ApplicationRecord
  belongs_to :user
  validates :user, presence: true
  has_many :requests, class_name: 'BackgroundBatch::Request', dependent: :destroy
  validates :requests, length: { minimum: 1 }
  validates_associated :requests
  accepts_nested_attributes_for :requests
  after_validation :create_batch, on: :create
  after_commit :create_workers, on: :create

  PERMITTED_ATTRIBUTES = [
    :uuid,
    requests_attributes: [
      :default_account_list,
      :path,
      :request_params,
      :request_body,
      :request_headers,
      :request_method,
      :uuid
    ]
  ].freeze

  def status
    @status ||= Sidekiq::Batch::Status.new(batch_id)
  end

  protected

  def create_batch
    @batch = Sidekiq::Batch.new
    self.batch_id = @batch.bid
  end

  def create_workers
    @batch.jobs do
      requests.each { |request| BackgroundBatch::RequestWorker.perform_async(request.id) }
    end
  end
end
