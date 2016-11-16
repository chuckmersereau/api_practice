class Api::V2::AccountLists::PrayerLettersAccountsController < Api::V2::AccountListsController
  def sync
    load_resource
    authorize @resource
    @resource.queue_subscribe_contacts
    render_200
  end

  private

  def load_resource
    @resource ||= resource_scope.prayer_letters_account
    raise ActiveRecord::RecordNotFound unless @resource
  end

  def build_resource
    @resource ||= resource_scope.prayer_letters_account&.build || PrayerLettersAccount.new
    @resource.assign_attributes(resource_params.merge(account_list_id: current_account_list.id))
    authorize @resource
  end

  def resource_attributes
    [:oauth2_token, :valid_token]
  end

  def resource_scope
    current_account_list
  end
end
