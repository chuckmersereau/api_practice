class DuplicateRecordPairSerializer < ApplicationSerializer
  attributes :reason,
             :ignore

  belongs_to :account_list
  has_many :records

  def reason
    _(object.reason)
  end
end
