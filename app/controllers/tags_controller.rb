class TagsController < ApplicationController
  def create
    return if params[:add_tag_name].blank?
    contacts = current_account_list.contacts.where(id: params[:add_tag_contact_ids].split(','))
    contacts.each do |c|
      c.tag_list.add(params[:add_tag_name].downcase.split(/[,;]/).map(&:strip))
      c.save
    end
  end

  def destroy
    return if params[:remove_tag_name].blank?
    if params[:all_contacts]
      tag_type = 'Contact'
      taggables = current_account_list.contacts
    elsif params[:all_tasks]
      tag_type = 'Activity'
      taggables = current_account_list.tasks
    else
      return if params[:remove_tag_contact_ids].blank?
      tag_type = 'Contact'
      taggables = current_account_list.contacts
                  .where(id: params[:remove_tag_contact_ids].split(','))
    end
    taggables = taggables.tagged_with(quote_tag(params[:remove_tag_name]))
    ActsAsTaggableOn::Tagging.joins(:tag)
      .where(taggable_type: tag_type, taggable_id: taggables.pluck(:id))
      .where(tags: { name: params[:remove_tag_name] }).destroy_all
  end

  private

  def quote_tag(tag_name)
    return "\"#{tag_name}\"" unless tag_name.include?('"')
    return "\'#{tag_name}\'" unless tag_name.include?("'")
    tag_name
  end
end
