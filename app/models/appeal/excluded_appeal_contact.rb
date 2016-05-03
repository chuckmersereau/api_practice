class Appeal::ExcludedAppealContact < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :contact

  validates :appeal, presence: true
  validates :contact, presence: true
end
