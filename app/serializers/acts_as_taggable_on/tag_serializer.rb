class ActsAsTaggableOn::TagSerializer < ActiveModel::Serializer
  type 'tags'

  attribute :name
end
