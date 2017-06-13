class Api::V2::Tasks::CommentsPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = { person: Api::V2::Contacts::PeoplePreloader }.freeze
  FIELD_ASSOCIATION_MAPPING = {}.freeze

  private

  def serializer_class
    ActivityCommentSerializer
  end
end
