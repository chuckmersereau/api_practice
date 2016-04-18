class Person::OrganizationAccountsController < ApplicationController
  skip_before_action :ensure_setup_finished, only: [:new, :create]

  respond_to :js, :html

  def new
    @organization = Organization.find(params[:id])
    if @organization.requires_username_and_password?
      @organization_account = current_user.organization_accounts.new(organization: @organization)

      respond_to do |format|
        format.js
      end
    else
      @organization_account = current_user.organization_accounts.create!(organization_id: @organization.id)

      respond_to do |format|
        format.js { render :create }
      end
    end
  end

  def create
    @organization_account = current_user.organization_accounts.new(person_organization_account_params)
    @organization = @organization_account.organization

    respond_to do |format|
      if save_account
        format.js
      else
        format.js { render :new }
      end
    end
  end

  def edit
    @organization_account = current_user.organization_accounts.find(params[:id])
  end

  def update
    @organization_account = current_user.organization_accounts.find(params[:id])
    unless @organization_account.update_attributes(person_organization_account_params)
      render :edit
    end
  end

  def destroy
    @organization_account = current_user.organization_accounts.find(params[:id])
    @organization_account.destroy
    redirect_to accounts_path
  end

  private

  def save_account
    return false unless @organization
    @organization_account.save
  rescue RuntimeError => e
    Rollbar.error(e)
    error_message = format(_('Error connecting to %{org_name} server'), org_name: @organization.name)
    @organization_account.errors.add(:base, error_message)
    false
  end

  def person_organization_account_params
    params.require(:person_organization_account).permit(:username, :password, :organization_id)
  end
end
