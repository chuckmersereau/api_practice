class User < Person
  include AdobeCampaignable

  has_many :account_list_users, dependent: :destroy
  has_many :account_lists, -> { uniq }, through: :account_list_users
  has_many :account_list_coaches, dependent: :destroy, foreign_key: :coach_id
  has_many :account_list_invites
  has_many :contacts, through: :account_lists
  has_many :account_list_entries, through: :account_lists
  has_many :designation_accounts, through: :account_list_entries
  has_many :donations, through: :designation_accounts
  has_many :designation_profiles, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy
  has_many :partner_companies, through: :account_lists, source: :companies
  has_many :imports, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :background_batches, dependent: :destroy
  has_many :tasks, through: :account_lists

  devise :trackable
  store :preferences, accessors: [:time_zone, :locale, :locale_display, :contacts_filter,
                                  :tasks_filter, :contacts_view_options,
                                  :tab_orders, :developer, :admin]
  validate :default_account_list_is_valid, if: 'default_account_list.present?'

  PERMITTED_ATTRIBUTES = Person::PERMITTED_ATTRIBUTES.deep_dup.concat(
    [preferences: [
      :contacts_filter,
      :contacts_view_options,
      :default_account_list,
      :locale,
      :locale_display,
      :tasks_filter,
      :tab_orders,
      :time_zone
    ]]
  ).freeze

  # Queue data imports
  def queue_imports
    organization_accounts.each do |oa|
      oa.queue_import_data unless oa.last_download
      # oa.queue_import_data unless oa.downloading? || (oa.last_download && oa.last_download > 1.day.ago)
    end
  end

  def tab_order_by_location(location)
    orders = tab_orders || {}
    orders[location] || []
  end

  def merge(other)
    User.transaction do
      other.account_list_users.each do |other_alu|
        other_alu.update_column(:user_id, id) unless account_list_users.find { |alu| alu.account_list_id == other_alu.account_list_id }
      end

      other.designation_profiles.each do |other_dp|
        other_dp.update_column(:user_id, id) unless designation_profiles.find { |dp| dp.code == other_dp.code }
      end

      imports.update_all(user_id: id)
    end

    super
  end

  def setup
    return 'no account_lists' if account_lists.empty?
    return 'no default_account_list' if default_account_list_record.nil?
    return 'no organization_account on default_account_list' if default_account_list_record.organization_accounts.empty?
  end

  def default_account_list_record
    account_lists.find_by(id: default_account_list)
  end

  def designation_numbers(organization_id)
    designation_accounts.where(organization_id: organization_id).pluck('designation_number')
  end

  def self.from_access_token(token)
    return unless token.present?
    get_user_from_access_token(token) ||
      get_user_from_cas_oauth(token)
  end

  def self.get_user_from_access_token(token)
    user = User.find_by(access_token: token)
    return if user.blank?
    return user if user.relay_accounts.any?
    real_user = get_relay_account_user_from_token(token)

    return user unless real_user && real_user.id != user.id
    real_user.merge(user)
    real_user
  end

  def self.get_user_from_cas_oauth(token)
    user = get_relay_account_user_from_token(token)
    return unless user
    user.update(access_token: token)
    user
  end

  def self.get_relay_account_user_from_token(token)
    begin
      response = RestClient.get("http://oauth.ccci.us/users/#{token}")
    rescue RestClient::Unauthorized
      return
    end

    return if response.blank?
    guid = JSON.parse(response.to_s)['guid']
    return unless guid.present?
    relay_account = Person::RelayAccount.find_by('lower(relay_remote_id) = ?', guid.downcase)
    return unless relay_account&.person
    relay_account.person.to_user
  end

  # Find a user from a guid, regardless of whether they have a Relay or a Key account,
  # `Person::KeyAccount` and `Person::RelayAccount` both use the same db table,
  # so we only need one query.
  def self.find_by_guid(guid)
    account = if guid.is_a?(Array)
                Person::RelayAccount.find_by('lower(relay_remote_id) IN (?)', guid.map(&:downcase))
              else
                Person::RelayAccount.find_by('lower(relay_remote_id) = ?', guid.downcase)
              end
    account&.person&.to_user
  end

  def self.find_by_email(email)
    Person::KeyAccount.where('lower(email) = ?', email.downcase)
                      .limit(1)
                      .try(:first)
                      .try(:user)
  end

  def to_person
    Person.find(id)
  end

  def assign_time_zone(timezone_object)
    raise ArgumentError unless timezone_object.is_a?(ActiveSupport::TimeZone)

    self.time_zone = timezone_object.name
  end

  def can_manage_sharing?(account_list)
    # We only allow users to manage sharing if the donor system linked them to
    # the account list via a designation profile. Otherwise, they only have
    # access through an invite from another user and they are not allowed to
    # manage sharing.
    designation_profiles.where(account_list: account_list).any?
  end

  def remove_user_access(account_list)
    account_list_users.where(account_list: account_list).find_each(&:destroy)
  end

  def contacts_filter=(hash)
    old_value = contacts_filter || {}
    super(old_value.merge(hash))
  end

  def preferences=(preferences_attributes)
    return unless preferences_attributes
    preferences_attributes = preferences_attributes.with_indifferent_access
    if preferences_attributes[:default_account_list]
      self.default_account_list = preferences_attributes.delete :default_account_list
    end
    super(preferences.merge(preferences_attributes))
  end

  def readable_account_lists
    AccountList.readable_by(self)
  end

  def email_address
    email&.email
  end

  private

  def default_account_list_is_valid
    return if account_lists.map(&:id).include?(default_account_list)

    errors.add(:default_account_list, 'is not included in list of account_lists')
  end
end
