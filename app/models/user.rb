class User < Person
  has_many :account_list_users, dependent: :destroy
  has_many :account_lists, through: :account_list_users
  has_many :account_list_invites
  has_many :contacts, through: :account_lists
  has_many :account_list_entries, through: :account_lists
  has_many :designation_accounts, through: :account_list_entries
  has_many :donations, through: :designation_accounts
  has_many :designation_profiles, dependent: :destroy
  has_many :partner_companies, through: :account_lists, source: :companies
  has_many :imports, dependent: :destroy

  devise :trackable
  store :preferences, accessors: [:time_zone, :locale, :setup, :contacts_filter,
                                  :tasks_filter, :default_account_list, :contacts_view_options,
                                  :tab_orders, :developer, :admin]

  after_create :set_setup_mode

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

  def setup_mode?
    setup == true || organization_accounts.blank?
  end

  def setup_finished!
    return unless setup_mode?
    self.setup = [:import, :goal, :contacts]
    save(validate: false)
  end

  def designation_numbers(organization_id)
    designation_accounts.where(organization_id: organization_id).pluck('designation_number')
  end

  def self.from_omniauth(provider, auth_hash)
    # look for an authenticated record from this provider
    user = provider.find_authenticated_user(auth_hash)
    unless user
      # TODO: hook into IdM to find other identities for this person
      # that might link to an existing user in MPDX

      # Create a new user
      user = provider.create_user_from_auth(auth_hash)
    end
    user
  end

  def self.from_access_token(token)
    return unless token.present?
    get_user_from_access_token(token) ||
      get_user_from_cas_oauth(token)
  end

  def self.get_user_from_access_token(token)
    user = User.find_by_access_token(token)
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
    relay_account = Person::RelayAccount.find_by('lower(remote_id) = ?', guid.downcase)
    return unless relay_account && relay_account.person
    relay_account.person.to_user
  end

  def to_person
    Person.find(id)
  end

  def setup
    super || []
  end

  def stale?
    return false unless last_sign_in_at
    last_sign_in_at < 6.months.ago
  end

  def can_manage_sharing?(account_list)
    # We only allow users to manage sharing if the donor system linked them to
    # the accoutn list via a designation profile. Otherwise, they only have
    # access through a invite from another user and they are not allowed to
    # manage sharing.
    designation_profiles.where(account_list: account_list).any?
  end

  def remove_access(account_list)
    account_list_users.where(account_list: account_list).find_each(&:destroy)
  end

  private

  def set_setup_mode
    if preferences[:setup].nil?
      preferences[:setup] = true
      save(validate: false)
    end
  end
end
