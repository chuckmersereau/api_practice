class Appeal::ExcludedAppealContact < ApplicationRecord
  belongs_to :appeal
  belongs_to :contact

  validates :appeal, presence: true
  validates :contact, presence: true
end
