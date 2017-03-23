class ImportSerializer < ApplicationSerializer
  attributes :account_list_id,
             :file_constants,
             :file_constants_mappings,
             :file_headers,
             :file_headers_mappings,
             :file_url,
             :group_tags,
             :groups,
             :import_by_group,
             :in_preview,
             :override,
             :source,
             :tags

  belongs_to :user

  has_many :sample_contacts do |serializer|
    CsvImport.new(serializer.object).sample_contacts
  end

  def file_url
    object.file.url
  end
end
