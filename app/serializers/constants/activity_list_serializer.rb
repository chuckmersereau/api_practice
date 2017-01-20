class Constants::ActivityListSerializer < ActiveModel::Serializer
  delegate :activities, to: :object

  type :activity_list
  attributes :activities
end
