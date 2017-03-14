module BulkTagDeleteable
  def quote_tag_name_for_query(name)
    return "\"#{name}\"" unless name.include?('"')
    return "\'#{name}\'" unless name.include?("'")

    name
  end

  def tag_name
    params.dig(:data, :attributes, :name)
  end

  def taggable_ids
    quoted_tag_name = quote_tag_name_for_query(tag_name)

    tags_scope.tagged_with(quoted_tag_name).pluck(:id)
  end

  def tags_scope
    raise NotImplementedError, 'must implement this in the controller directly'
  end
end
