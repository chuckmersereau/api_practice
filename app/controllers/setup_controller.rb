class SetupController < ApplicationController
  include Wicked::Wizard

  skip_before_action :ensure_setup_finished
  before_action :ensure_org_account, only: :show

  steps :org_accounts, :social_accounts, :settings, :finish

  def show
    case step
    when :org_accounts
      skip_step if current_user.organization_accounts.present?
    when :social_accounts
    when :settings
      @preference_set = PreferenceSet.new(user: current_user, account_list: current_account_list)
      @account_list_organizations = build_account_list_organizations
      @preferences_prefills = build_preferences_prefills
    when :finish
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

  def build_preferences_prefills
    current_user.organization_accounts.collect(&:organization).uniq.each_with_object({}) do |org, hash|
      hash[org.name] = {
        country: org.country,
        currency: org.default_currency_code
      }
    end
  end

  def build_account_list_organizations
    current_user.account_lists.each_with_object({}) do |al, hash|
      hash[al.name] = Organization.includes(designation_profiles: [:account_list])
                                  .where(account_lists: { id: al.id })
                                  .uniq.pluck(:name)
    end
  end
end
