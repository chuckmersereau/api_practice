class ActsAsTaggableOn::TagSerializer < ActiveModel::Serializer
  type 'tags'
  attributes :id, :name
end
