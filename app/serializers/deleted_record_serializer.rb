class DeletedRecordSerializer < ApplicationSerializer
  attributes :deleted_at, :deletable_type, :deletable_id

  belongs_to :account_list
  belongs_to :deletable, polymorphic: true
  belongs_to :deleted_by, class_name: 'Person', foreign_key: 'deleted_by_id'
end
