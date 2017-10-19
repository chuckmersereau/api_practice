# This class serves as a wrapper around the Gibbon class.
# It basically makes the process of communicating with the Mail Chimp API easier.
class MailChimp::GibbonWrapper
  COUNT_PER_PAGE = 100
  List = Struct.new(:id, :name, :open_rate)

  delegate :api_key,
           :primary_list_id,
           :mail_chimp_appeal_list,
           to: :mail_chimp_account

  delegate :batches, to: :gibbon

  attr_accessor :mail_chimp_account, :gibbon, :validation_error

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
  end

  def lists
    @lists ||= build_list_objects || []
  end

  def list(list_id)
    lists.find { |list| list.id == list_id }
  end

  def primary_list
    list(primary_list_id) if primary_list_id.present?
  end

  def validate_key
    return false unless api_key.present?
    begin
      @list_response ||= gibbon.lists.retrieve
      active = true
    rescue Gibbon::MailChimpError => error
      active = false
      @validation_error = error.detail
    end
    mail_chimp_account.update_column(:active, active) unless mail_chimp_account.new_record?
    active
  end

  def active_and_valid?
    active? && validate_key
  end

  def datacenter
    api_key.to_s.split('-').last
  end

  def lists_available_for_appeals
    lists.select { |list| list.id != primary_list_id }
  end

  def lists_available_for_newsletters
    lists.select { |list| list.id != mail_chimp_appeal_list.try(:appeal_list_id) }
  end

  def export_to_list(contacts)
    MailChimpAccount::Exporter.new(self).export_to_list(contacts)
  end

  def queue_export_if_list_changed
    queue_export_to_primary_list if changed.include?('primary_list_id')
  end

  def set_active
    self.active = true
  end

  def gibbon
    @gibbon ||= Gibbon::Request.new(api_key: api_key)
    @gibbon.timeout ||= 600
    @gibbon
  end

  def list_emails(list_id)
    list_members(list_id).map { |list_member| list_member['email_address'] }
  end

  def list_members(list_id)
    page = list_members_page(list_id, 0)
    total_items = page['total_items']
    members = page['members']

    more_pages = (total_items.to_f / COUNT_PER_PAGE).ceil - 1
    more_pages.times do |i|
      page = list_members_page(list_id, COUNT_PER_PAGE * (i + 1))
      members.concat(page['members'])
    end

    members
  end

  def list_member_info(list_id, emails)
    # The MailChimp API v3 doesn't provide an easy, syncronous way to retrieve
    # member info scoped to a set of email addresses, so just pull it all and
    # filter it for now.
    email_set = emails.to_set
    list_members(list_id).select { |m| m['email_address'].in?(email_set) }
  end

  def appeal_open_rate
    list(mail_chimp_appeal_list.try(:appeal_list_id)).try(:open_rate)
  end

  def relevant_emails
    if sync_all_active_contacts
      active_contacts_emails
    else
      newsletter_emails
    end
  end

  def primary_list_name
    primary_list.try(:name)
  end

  def lists_available_for_newsletters_formatted
    lists_available_for_newsletters.collect { |l| { name: l.name, id: l.id } }
  end

  def lists_link
    "https://#{datacenter}.admin.mailchimp.com/lists/"
  end

  def gibbon_list_object(list_id)
    gibbon.lists(list_id)
  end

  private

  def retrieve_lists
    return unless api_key.present?

    gibbon.lists.retrieve(params: { count: 100 })['lists']
  end

  def build_list_objects
    retrieve_lists.map do |list|
      List.new(list['id'], list['name'], list.dig('stats', 'open_rate'))
    end
  end

  def list_members_page(list_id, offset)
    gibbon.lists(list_id).members.retrieve(
      params: { count: COUNT_PER_PAGE, offset: offset }
    )
  end
end
