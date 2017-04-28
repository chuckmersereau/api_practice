class PledgeSerializer < ApplicationSerializer
  attributes :amount,
             :expected_date,
             :received_not_processed

  belongs_to :account_list
  belongs_to :contact
  belongs_to :donation
end
