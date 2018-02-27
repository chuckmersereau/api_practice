class Contact::Filter::ExcludeTags < Contact::Filter::Base
  def execute_query(contacts, filters)
    tags = parse_list(filters[:exclude_tags])
    contacts.tagged_with(escape_backslashes(tags), exclude: true)
  end

  private

  # SQL's ILIKE query requires backslashes to be escaped, but the
  # ActsAsTaggableOn gem doesn't do this, so we must.
  def escape_backslashes(tags)
    tags.map { |t| t.gsub('\\', '\\\\\\') }
  end
end
