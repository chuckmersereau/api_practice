class ImportSerializer < ApplicationSerializer
  attributes :account_list_id,
             :file,
             :file_headers,
             :groups,
             :group_tags,
             :import_by_group,
             :in_preview,
             :override,
             :source,
             :tags

  belongs_to :user

  def file_headers
    object.file_headers&.split(',')
  end
end
