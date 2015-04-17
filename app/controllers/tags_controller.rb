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
    p params
    return if params[:remove_tag_name].blank?
    if params[:all_contacts] == '1'
      contacts = current_account_list.contacts
      contacts.each do |c|
        c.tag_list.remove(params[:remove_tag_name].downcase)
        c.save
      end
    elsif params[:all_tasks] == '1'
      tasks = current_account_list.tasks
      tasks.each do |t|
        t.tag_list.remove(params[:remove_tag_name].downcase)
        t.save
      end
    else
      contacts = current_account_list.contacts.where(id: params[:remove_tag_contact_ids].split(','))
      contacts.each do |c|
        c.tag_list.remove(params[:remove_tag_name].downcase)
        c.save
      end
    end
  end
end
