class Api::V1::Preferences::ContactsController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_current_user_preferences
  end

  private

  def load_current_user_preferences
    result = []
    if current_user.contact_tabs_sort_data != ''
      current_user.contact_tabs_sort_data.split(',').map do |key|
        result << ContactExhibit::TABS_ACTIONS.select { |i| i[:key] == key }.first
      end
    else
      result = ContactExhibit::TABS_ACTIONS
    end
    @preferences[:contact_tabs_labels] = result
  end
end
