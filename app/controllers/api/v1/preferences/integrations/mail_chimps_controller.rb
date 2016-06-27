class Api::V1::Preferences::Integrations::MailChimpsController < Api::V1::BaseController
  def show
    load_mail_chimp
    build_mail_chimp
    render_mail_chimp
  end

  def update
    load_mail_chimp
    build_mail_chimp
    return render json: { errors: @mail_chimp.validation_error }, status: 400 unless save_mail_chimp
    render_mail_chimp
  end

  protected

  def load_mail_chimp
    @mail_chimp ||= current_account_list.mail_chimp_account
  end

  def build_mail_chimp
    @mail_chimp ||= if $rollout.active?(:mail_chimp_auto_log, current_account_list)
                      current_account_list.build_mail_chimp_account(auto_log_campaigns: true)
                    else
                      current_account_list.build_mail_chimp_account
                    end
    @mail_chimp.attributes = mail_chimp_params
  end

  def save_mail_chimp
    @mail_chimp.save
  end

  def render_mail_chimp
    render json: {
      mail_chimp: {
        id: @mail_chimp.id,
        lists_present: @mail_chimp.lists.present?,
        api_key: @mail_chimp.api_key,
        validation_error: @mail_chimp.validation_error,
        active: @mail_chimp.active?,
        validate_key: @mail_chimp.validate_key,
        auto_log_campaigns: @mail_chimp.auto_log_campaigns,
        primary_list_id: @mail_chimp.primary_list_id,
        primary_list_name: @mail_chimp.primary_list.try(:name),
        lists_available_for_newsletters: @mail_chimp.lists_available_for_newsletters.collect { |l| { name: l.name, id: l.id } },
        lists_link: "https://#{@mail_chimp.datacenter}.admin.mailchimp.com/lists/",
        valid: current_account_list.valid_mail_chimp_account
      }
    }
  end

  def mail_chimp_params
    return {} unless mail_chimp_params = params[:mail_chimp]
    mail_chimp_params.permit(:api_key, :grouping_id, :primary_list_id, :auto_log_campaigns)
  end
end
