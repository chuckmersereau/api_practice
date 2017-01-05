class ActsAsTaggableOn::TagSerializer < ApplicationSerializer
  type 'tags'

  attribute :name
end
