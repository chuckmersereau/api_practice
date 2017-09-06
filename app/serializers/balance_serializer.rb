class BalanceSerializer < ApplicationSerializer
  belongs_to :resource
  attributes :balance
end
