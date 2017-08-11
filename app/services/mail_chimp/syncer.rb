# This class is used to manage a two way sync between MailChimp and MPDX.
class MailChimp::Syncer
  Gibbon::Request.timeout = 600

  attr_reader :mail_chimp_account, :list_id

  delegate :interest_categories, to: :mc_list

  def initialize(mail_chimp_account, list_id = nil)
    @mail_chimp_account = mail_chimp_account
    @list_id = list_id || mail_chimp_account.primary_list_id
    @use_primary_list = mail_chimp_account.primary_list_id == list_id
  end

  def two_way_sync_with_primary_list
    MailChimp::ConnectionHandler.new(mail_chimp_account)
                                .call_mail_chimp(self, :two_way_sync_with_primary_list!)
  end

  def two_way_sync_with_primary_list!
    setup_webhooks
    import_mail_chimp_subscribers
    export_mpdx_contacts_to_mail_chimp
  end

  private

  def import_mail_chimp_subscribers
    delete_mail_chimp_members

    MailChimp::Importer.new(mail_chimp_account).import_all_members
  end

  def export_mpdx_contacts_to_mail_chimp
    MailChimp::ExportContactsWorker.perform_async(mail_chimp_account.id, mail_chimp_account.primary_list_id, nil)
  end

  def delete_mail_chimp_members
    mail_chimp_account.mail_chimp_members.where(list_id: list_id).delete_all
    mail_chimp_account.mail_chimp_members.reload
  end

  def setup_webhooks
    return if does_not_require_webhooks_setup?

    generate_token_if_necessary

    create_webhooks
  end

  def create_webhooks
    mail_chimp_webhooks.create(
      body: {
        url: webhook_url,
        events: {
          campaign: true,
          cleaned: true,
          profile: true,
          subscribe: true,
          unsubscribe: true,
          upemail: true
        },
        sources: {
          admin: true,
          api: false,
          user: true
        }
      }
    )
  end

  def generate_token_if_necessary
    mail_chimp_account.update(webhook_token: SecureRandom.hex(32)) if mail_chimp_account.webhook_token.blank?
  end

  def does_not_require_webhooks_setup?
    not_a_production_or_stage_environment? ||
      mail_chimp_account.webhook_token.present? &&
        mail_chimp_webhooks.retrieve['webhooks'].find { |webhook| webhook['url'] == webhook_url }
  end

  def not_a_production_or_stage_environment?
    !Rails.env.production? && !Rails.env.staging?
  end

  def appeal_export?
    @is_appeal_export
  end

  def gibbon
    @gibbon ||= Gibbon::Request.new(api_key: mail_chimp_account.api_key)
  end

  def mail_chimp_webhooks
    @mail_chimp_webhooks ||= mail_chimp_list.webhooks
  end

  def mail_chimp_list
    @mail_chimp_list ||= gibbon.lists(list_id)
  end

  def use_primary_list?
    @use_primary_list
  end

  def email_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def webhook_url
    (Rails.env.development? ? 'http://' : 'https://') +
      Rails.application.routes.default_url_options[:host] + '/mail_chimp_webhook/' + mail_chimp_account.webhook_token
  end
end
