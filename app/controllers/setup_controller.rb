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
      @account_list_organizations = build_al_organizatoins
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

  def guess_country(org_name)
    ['Campus Crusade for Christ - ', 'Cru - ', 'Power To Change - ', 'Gospel For Asia'].each do |prefix|
      org_name = org_name.gsub(prefix, '')
    end
    org_name = org_name.split(' - ').last if org_name.include? ' - '
    org_name = org_name.strip
    return 'United States' if org_name == 'USA'
    return 'Canada' if org_name == 'CAN'
    match = ::CountrySelect::COUNTRIES_FOR_SELECT.any? do |country|
      country[:name] == org_name || country[:alternatives].split(' ').include?(org_name)
    end
    return org_name.titleize if match
    nil
  end

  def build_preferences_prefills
    current_user.organization_accounts.collect(&:organization).uniq.each_with_object({}) do |org, hash|
      hash[org.name] = {
        country: guess_country(org.name),
        currency: org.default_currency_code
      }
    end
  end

  def build_al_organizatoins
    current_user.account_lists.each_with_object({}) do |al, hash|
      hash[al.name] = Organization.includes(designation_accounts: [:account_lists])
                                  .where(account_lists: { id: al.id })
                                  .uniq.pluck(:name)
    end
  end
end
