module TagsEagerLoading
  extend ActiveSupport::Concern

  included do
    original_tag_list = instance_method(:tag_list)

    define_method(:tag_list) do
      # acts_as_taggable caches with this variable
      @tag_list ||= tags.map(&:name) if tags.loaded?

      original_tag_list.bind(self).call
    end
  end
end
