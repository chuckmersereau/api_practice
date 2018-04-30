class ExportLogSerializer < ApplicationSerializer
  attributes :export_at,
             :type,
             :params
  belongs_to :user

  def params
    JSON.parse(object.params)
  rescue JSON::ParserError
    object.params
  end
end
