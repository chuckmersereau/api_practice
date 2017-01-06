class ActsAsTaggableOn::TagSerializer < ActiveModel::Serializer
  type 'tags'
  attributes :id, :name

  def id
    object.uuid
  end
end
