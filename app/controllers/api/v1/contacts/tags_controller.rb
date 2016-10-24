class Api::V1::Contacts::TagsController < Api::V1::BaseController
  def index
    render json: current_account_list.contact_tags.to_json
  end

  def destroy
    tags_params.each do |_key, tag|
      if tag[:all_contacts]
        tag_type = 'Contact'
        taggables = current_account_list.contacts
      elsif tag[:all_tasks]
        tag_type = 'Activity'
        taggables = current_account_list.tasks
      else
        return if tag[:contact_ids].blank?
        tag_type = 'Contact'
        taggables = current_account_list.contacts
                                        .where(id: tag[:contact_ids].split(','))
      end
      taggables = taggables.tagged_with(quote_tag(tag[:name]))
      ActsAsTaggableOn::Tagging.joins(:tag)
                               .where(taggable_type: tag_type, taggable_id: taggables.pluck(:id))
                               .where(tags: { name: tag[:name] }).destroy_all
    end
    render nothing: true
  end

  def bulk_create
    render nothing: true, status: 400 if params[:add_tag_name].blank? || !params[:add_tag_contact_ids]
    contacts = current_account_list.contacts.where(id: params[:add_tag_contact_ids].split(','))
    contacts.each do |c|
      c.tag_list.add(params[:add_tag_name].downcase.split(/[,;]/).map(&:strip))
      c.save
    end
    render nothing: true
  end

  private

  def tags_params
    return {} unless tags_params = params[:tags]
    tags_params
  end

  def quote_tag(tag_name)
    return "\"#{tag_name}\"" unless tag_name.include?('"')
    return "\'#{tag_name}\'" unless tag_name.include?("'")
    tag_name
  end
end
