class PledgeSerializer < ApplicationSerializer
  attributes :amount,
             :expected_date,
             :processed,
             :received_not_processed

  belongs_to :account_list
  belongs_to :contact
  has_many :donations
end
