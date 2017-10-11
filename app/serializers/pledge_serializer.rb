class PledgeSerializer < ApplicationSerializer
  attributes :amount,
             :expected_date,
             :status

  belongs_to :account_list
  belongs_to :contact
  has_many :donations
end
