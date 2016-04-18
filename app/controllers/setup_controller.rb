class SetupController < ApplicationController
  include Wicked::Wizard

  skip_before_action :ensure_setup_finished
  before_action :ensure_org_account, only: :show

  steps :org_accounts, :social_accounts, :finish

  def show
    if step == :finish
      current_user.setup_finished!
      redirect_to '/'
      return
    end
    render_wizard
  end

  protected

  def ensure_org_account
    return if step == :org_accounts || current_user.organization_accounts.present?
    redirect_to wizard_path(:org_accounts), alert: _('You need to be connected to an organization to use MPDX.')
    false
  end
end
