class PreferencesController < ApplicationController
  def index
    @page_title = _('{{title}}')
  end

  def update
    @preference_set = PreferenceSet.new(params[:preference_set].merge!(user: current_user, account_list: current_account_list))
    if @preference_set.save
      if params[:preference_set][:completed_welcome_step] && current_user.setup.include?(:goal)
        current_user.setup.delete :goal
        current_user.save
      end
      path = params[:redirect] || preferences_path
      redirect_to path, notice: _('Preferences saved')
    else
      flash.now[:alert] = @preference_set.errors.full_messages.join('<br />').html_safe
      render 'index'
    end
  end

  def update_tab_order
    current_user.tab_orders ||= {}
    current_user.tab_orders[params[:location]] = params[:tabs]
    current_user.save
    render nothing: true
  end

  def complete_welcome_panel
    key = params[:key].try(:to_sym)
    if current_user.setup.is_a?(Array) && current_user.setup.include?(key)
      current_user.setup.delete(key)
      current_user.save!
    end
    render nothing: true
  end
end
