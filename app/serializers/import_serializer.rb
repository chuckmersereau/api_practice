class ImportSerializer < BaseSerializer
  attributes :id, :account_list_id, :source, :file, :tags, :override, :user_id, :source_account_id,
             :import_by_group, :groups, :group_tags
end
