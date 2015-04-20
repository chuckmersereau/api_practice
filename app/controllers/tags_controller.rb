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
      taggables = current_account_list.contacts
    elsif params[:all_tasks]
      taggables = current_account_list.tasks
    else
      taggables = current_account_list.contacts.where(id: params[:remove_tag_contact_ids].split(','))
    end
    taggables.each do |o|
      next unless o.tag_list.include?(params[:remove_tag_name].downcase)
      o.tag_list.remove(params[:remove_tag_name].downcase)
      o.save
    end
  end
end
