class Api::V2::AccountLists::Appeals::ExportToMailchimpController < Api::V2::AccountLists::AppealsController
	def show
		@resource.queue_export_appeal_contacts(contact_ids, params['appeal-list-id'], current_appeal.id)
		render_200
	end

  def load_resource
  	@resource ||= resource_scope
  	raise ActiveRecord::RecordNotFound unless @resource
  end

  def resource_scope 
  	current_account_list.mail_chimp_account
  end

  private

  def contacts
  	current_appeal.contacts
  end

  def contact_ids
  	contacts.pluck(:id)
  end
end