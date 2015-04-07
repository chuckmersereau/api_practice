# Hacky monkey patch because the acts_as_taggable gem doesn't work well with eager loading
# See https://github.com/mbleigh/acts-as-taggable-on/issues/9
module TagsEagerLoading
  extend ActiveSupport::Concern

  included do
    original_tag_list = instance_method(:tag_list)

    define_method(:tag_list) do
      # acts_as_taggable caches with this variable using a TagList
      @tag_list ||= ActsAsTaggableOn::TagList.new(*tags.map(&:name)) if tags.loaded?

      original_tag_list.bind(self).call
    end
  end
end
