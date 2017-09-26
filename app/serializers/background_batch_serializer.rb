class BackgroundBatchSerializer < ApplicationSerializer
  attributes :total, :pending
  has_many :requests

  def total
    object.requests.count
  end

  def pending
    object.requests.pending.count
  end
end
