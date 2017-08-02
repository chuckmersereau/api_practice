class ExportLog < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :user

  validates :user_id, :export_at, :type, presence: true
end
