class CompanyPartnership < ApplicationRecord
  belongs_to :account_list
  belongs_to :company
end
