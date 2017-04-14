class AppealContact < ApplicationRecord
  belongs_to :appeal, foreign_key: 'appeal_id'
  belongs_to :contact
end
