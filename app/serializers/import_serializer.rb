class ImportSerializer < ApplicationSerializer
  attributes :account_list_id,
             :file,
             :groups,
             :group_tags,
             :import_by_group,
             :override,
             :source,
             :source_account_id,
             :tags,
             :user_id
end
