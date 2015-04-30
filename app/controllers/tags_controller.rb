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
      taggables = current_account_list.contacts.tagged_with(params[:remove_tag_name])
      tag_type = 'Contact'

    elsif params[:all_tasks]
      taggables = current_account_list.tasks.tagged_with(params[:remove_tag_name])
      tag_type = 'Activity'
    else
      taggableslist = current_account_list.contacts.where(id: params[:remove_tag_contact_ids].split(','))
      taggables = taggableslist.tagged_with(params[:remove_tag_name])
      tag_type = 'Contact'
    end
    ActsAsTaggableOn::Tagging.joins(:tag)
      .where(taggable_type: tag_type, taggable_id: taggables.pluck(:id))
      .where('tags.name' => params[:remove_tag_name]).destroy_all
  end
end
