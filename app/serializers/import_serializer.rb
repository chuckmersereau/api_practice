class ImportSerializer < ApplicationSerializer
  attributes :account_list_id,
             :file,
             :groups,
             :group_tags,
             :import_by_group,
             :override,
             :source,
             :tags

  belongs_to :account_list
  belongs_to :user
end
