module Concerns::Filter::SearchableInParts
  private

  def sql_condition_to_search_columns_in_parts(*columns)
    search_term_parts_hash.keys.collect do |part_key|
      columns.collect do |column|
        "#{column} ilike :#{part_key}"
      end.join(' OR ').prepend('(') + ')'
    end.flatten.join(' AND ').prepend('(') + ')'
  end

  def search_term_parts_hash
    @search_term_parts_hash ||= @search_term.gsub(/[,-]/, ' ').split(' ').each_with_object({}) do |search_term_part, hash|
      hash["search_part_#{hash.size}".to_sym] = "%#{search_term_part}%"
      hash
    end
  end

  def query_params(extra_params = {})
    { search: "%#{@search_term}%" }.merge(extra_params)
  end
end
