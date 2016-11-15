class MailChimpAccountPolicy < ApplicationPolicy
	def sync?
		resource_owner?
	end

	private

	def resource_owner?
		user.account_lists.ids.include?(resource.account_list.id)
	end
end