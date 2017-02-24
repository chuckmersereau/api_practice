class Api::V2::Contacts::Tags::BulkController < Api::V2Controller
  def destroy
    load_tags
    authorize_tags
    destroy_tags
  end

  private

  def tags_scope
    @contacts ||= Contact.where(account_list: account_lists).tap(&:first!)
  end

  def authorize_tags
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def destroy_tags
    @tags.destroy_all
    head :no_content
  end

  def load_tags
    @tags ||=
      ActsAsTaggableOn::Tagging.joins(:tag)
                               .where(taggable_type: 'Contact',
                                      taggable_id: taggable_ids,
                                      tags: { name: params[:tag_name] })
  end

  def taggable_ids
    tags_scope.tagged_with(quote_tag(params[:tag_name])).pluck(:id)
  end

  def quote_tag(tag_name)
    return "\"#{tag_name}\"" unless tag_name.include?('"')
    return "\'#{tag_name}\'" unless tag_name.include?("'")
    tag_name
  end

  def permitted_filters
    [:account_list_id]
  end
end
