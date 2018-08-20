class Person < ApplicationRecord
  include BetweenScopeable
  include YearCompletable
  include Deceased

  PAPER_TRAIL_IGNORED_FIELDS = [
    :updated_at, :global_registry_id, :global_registry_mdm_id, :sign_in_count,
    :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip
  ].freeze

  audited associated_with: :contact, except: PAPER_TRAIL_IGNORED_FIELDS

  between_scopes_for :anniversary
  between_scopes_for :birthday

  RELATIONSHIPS_MALE =
    [_('Husband'), _('Son'), _('Father'), _('Brother'), _('Uncle'), _('Nephew'), _('Cousin (Male)'), _('Grandfather'),
     _('Grandson')].freeze
  RELATIONSHIPS_FEMALE =
    [_('Wife'), _('Daughter'), _('Mother'), _('Sister'), _('Aunt'), _('Niece'), _('Cousin (Female)'), _('Grandmother'),
     _('Granddaughter')].freeze
  TITLES = [_('Mr.'), _('Mrs.'), _('Miss'), _('Ms.'), _('Rev.'), _('Hon.'), _('Dr.')].freeze
  SUFFIXES = [_('Jr.'), _('Sr.')].freeze
  MARITAL_STATUSES = [_('Single'), _('Engaged'), _('Married'), _('Separated'), _('Divorced'), _('Widowed')].freeze

  belongs_to :master_person
  has_many :email_addresses,
           -> { order('email_addresses.primary::int desc') },
           dependent: :destroy,
           autosave: true
  has_one :primary_email_address,
          -> { where('email_addresses.primary' => true) },
          class_name: 'EmailAddress',
          foreign_key: :person_id
  has_many :phone_numbers,
           -> { order('phone_numbers.primary::int desc') },
           dependent: :destroy
  has_one :primary_phone_number,
          -> { where('phone_numbers.primary' => true) },
          class_name: 'PhoneNumber',
          foreign_key: :person_id
  has_many :family_relationships,
           dependent: :delete_all
  has_many :related_people,
           through: :family_relationships
  has_one :company_position,
          -> { where('company_positions.end_date is null').order('company_positions.start_date desc') },
          class_name: 'CompanyPosition',
          foreign_key: :person_id
  has_many :company_positions,
           dependent: :delete_all
  has_many :twitter_accounts,
           class_name: 'Person::TwitterAccount',
           foreign_key: :person_id,
           dependent: :delete_all,
           autosave: true
  has_one :twitter_account,
          -> { where('person_twitter_accounts.primary' => true) },
          class_name: 'Person::TwitterAccount',
          foreign_key: :person_id
  has_many :facebook_accounts,
           class_name: 'Person::FacebookAccount',
           foreign_key: :person_id,
           dependent: :delete_all,
           autosave: true
  has_one :facebook_account,
          class_name: 'Person::FacebookAccount',
          foreign_key: :person_id
  has_many :linkedin_accounts,
           class_name: 'Person::LinkedinAccount',
           foreign_key: :person_id,
           dependent: :delete_all,
           autosave: true
  has_one :linkedin_account,
          -> { where('person_linkedin_accounts.valid_token' => true) },
          class_name: 'Person::LinkedinAccount',
          foreign_key: :person_id
  has_many :websites,
           class_name: 'Person::Website',
           foreign_key: :person_id,
           dependent: :delete_all,
           autosave: true
  has_one :website,
          -> { where('person_websites.primary' => true) },
          class_name: 'Person::Website',
          foreign_key: :person_id
  has_many :google_accounts,
           class_name: 'Person::GoogleAccount',
           foreign_key: :person_id,
           dependent: :destroy, autosave: true
  has_many :google_integrations, through: :google_accounts
  has_many :relay_accounts,
           class_name: 'Person::RelayAccount',
           foreign_key: :person_id,
           dependent: :delete_all
  has_many :organization_accounts,
           class_name: 'Person::OrganizationAccount',
           foreign_key: :person_id,
           dependent: :destroy
  has_many :key_accounts,
           class_name: 'Person::KeyAccount',
           foreign_key: :person_id,
           dependent: :delete_all
  has_many :companies,
           through: :company_positions
  has_many :donor_account_people
  has_many :donor_accounts,
           through: :donor_account_people
  has_many :contact_people,
           dependent: :destroy
  has_many :contacts,
           through: :contact_people
  has_many :account_lists,
           through: :contacts
  has_many :pictures,
           as: :picture_of,
           dependent: :destroy
  has_one :primary_picture,
          -> { where(primary: true) },
          as: :picture_of,
          class_name: 'Picture'
  has_many :comments,
           dependent: :destroy,
           class_name: 'ActivityComment'
  has_many :messages_sent,
           class_name: 'Message',
           foreign_key: :from_id,
           dependent: :delete_all
  has_many :messages_received,
           class_name: 'Message',
           foreign_key: :to_id,
           dependent: :delete_all
  has_many :google_contacts,
           autosave: true

  scope :alive, -> { where.not(deceased: true) }
  scope :by_anniversary, -> { order('anniversary_month, anniversary_day') }
  scope :by_birthday, -> { order('birthday_month, birthday_day') }
  scope :search_for_contacts, lambda { |contacts = []|
    joins(:contact_people)
      .where(contact_people: { contact: contacts })
  }

  accepts_nested_attributes_for :email_addresses,
                                reject_if: -> (e) { e[:email].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :phone_numbers,
                                reject_if: -> (p) { p[:number].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :family_relationships,
                                reject_if: -> (p) { p[:related_person_id].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :facebook_accounts,
                                reject_if: -> (p) { p[:username].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :twitter_accounts,
                                reject_if: -> (p) { p[:screen_name].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :linkedin_accounts,
                                reject_if: -> (p) { p[:public_url].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :pictures,
                                reject_if: -> (p) { p[:image].blank? && p[:image_cache].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :websites,
                                reject_if: -> (p) { p[:url].blank? },
                                allow_destroy: true

  PERMITTED_ATTRIBUTES = [
    :id,
    :anniversary_day,
    :anniversary_month,
    :anniversary_year,
    :birthday_day,
    :birthday_month,
    :birthday_year,
    :contact_ids,
    :created_at,
    :deceased,
    :employer,
    :first_name,
    :gender,
    :last_name,
    :legal_first_name,
    :marital_status,
    :middle_name,
    :occupation,
    :optout_enewsletter,
    :overwrite,
    :suffix,
    :title,
    :updated_at,
    :updated_in_db_at,
    {
      email_address: :email,
      email_addresses_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :email,
        :historic,
        :location,
        :overwrite,
        :primary,
        :source,
        :valid_values,
        :updated_in_db_at
      ],
      facebook_accounts_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite,
        :username,
        :updated_in_db_at
      ],
      family_relationships_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite,
        :related_person_id,
        :relationship,
        :updated_in_db_at
      ],
      linkedin_accounts_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite,
        :public_url,
        :updated_in_db_at
      ],
      phone_number: :number,
      phone_numbers_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :historic,
        :location,
        :number,
        :overwrite,
        :primary,
        :source,
        :valid_values,
        :updated_in_db_at
      ],
      pictures_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :image,
        :image_cache,
        :overwrite,
        :primary,
        :updated_in_db_at
      ],
      twitter_accounts_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite,
        :primary,
        :screen_name,
        :updated_in_db_at
      ],
      websites_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite,
        :primary,
        :url,
        :updated_in_db_at
      ]
    }
  ].freeze

  before_create :find_master_person
  after_destroy :clean_up_master_person

  before_save :check_state_for_mail_chimp_sync
  after_save :trigger_mail_chimp_syncs_to_relevant_contacts, if: :sync_with_mail_chimp_required?

  validates :first_name, presence: true

  alias_attribute :birth_year, :birthday_year
  alias_attribute :birth_month, :birthday_month
  alias_attribute :birth_day, :birthday_day
  alias_attribute :marriage_year, :anniversary_year
  alias_attribute :marriage_month, :anniversary_month
  alias_attribute :marriage_day, :anniversary_day
  alias_attribute :deceased_flag, :deceased

  global_registry_bindings mdm_id_column: :global_registry_mdm_id,
                           fields: { birth_year: :integer,
                                     birth_month: :integer,
                                     birth_day: :integer,
                                     marriage_year: :integer,
                                     marriage_month: :integer,
                                     marriage_day: :integer,
                                     first_name: :string,
                                     last_name: :string,
                                     title: :string,
                                     suffix: :string,
                                     gender: :string,
                                     marital_status: :string,
                                     middle_name: :string,
                                     deceased_flag: :boolean,
                                     occupation: :string,
                                     employer: :string }

  def to_s
    [first_name, last_name].join(' ')
  end

  def to_s_last_first
    [last_name, first_name].join(', ')
  end

  def add_spouse(spouse)
    relationship = case spouse.gender
                   when 'male'
                     'Husband'
                   when 'female'
                     'Wife'
                   else
                     'Wife' # Default to wife
                   end

    begin
      family_relationships.where(related_person_id: spouse.id).first_or_create(relationship: relationship)
    rescue ActiveRecord::RecordNotUnique
    end
  end

  def spouse
    family_relationships.find_by(relationship: %w(Husband Wife)).try(:related_person)
  end

  def to_user
    @user ||= User.find(id)
  end

  def email=(val)
    self.email_address = { email: val, primary: true }
  end

  def email
    primary_email_address || email_addresses.first
  end

  def facebook_accounts_attributes=(attributes_data)
    cleaned_data = reject_duplicate_facebook_username_data(attributes_data)
    super(cleaned_data)
  end

  def family_relationships_attributes=(data_object)
    case data_object
    when Array
      data_object.each { |attributes| assign_family_relationships_from_data_attributes(attributes) }
    when Hash
      assign_family_relationships_with_data_hash(data_object)
    end
  end

  def assign_family_relationships_from_data_attributes(attributes)
    if attributes[:id]
      fr = family_relationships.find(attributes[:id])
      if attributes[:_destroy] == '1' || attributes[:related_person_id].blank?
        fr.destroy
      else
        begin
          fr.update_attributes(attributes.except(:id, :_destroy))
        rescue ActiveRecord::RecordNotUnique
          fr.destroy
        end
      end
    elsif attributes[:related_person_id].present?
      FamilyRelationship.add_for_person(self, attributes)
    end
  end

  def assign_family_relationships_with_data_hash(hash)
    hash = hash.with_indifferent_access

    hash.each do |_, attributes|
      assign_family_relationships_from_data_attributes(attributes)
    end
  end

  def email_address=(hash)
    hash = hash.with_indifferent_access

    if hash['_destroy'].to_s == '1'
      email_addresses.find(hash['id']).destroy
    elsif hash['email'].present?
      EmailAddress.add_for_person(self, hash)
    end
  end

  def email_addresses_attributes=(attributes)
    if attributes.is_a?(Hash)
      attributes.each do |_, v|
        self.email_address = v
      end
    elsif attributes.is_a?(Array)
      attributes.each do |v|
        self.email_address = v
      end
    else
      super
    end
  end

  def phone_number=(hash)
    add_phone_number(hash)
  end

  def add_phone_number(hash)
    hash = hash.with_indifferent_access
    PhoneNumber.add_for_person(self, hash) if hash.with_indifferent_access['number'].present?
  end

  def phone_number
    primary_phone_number
  end

  def phone
    primary_phone_number.try(:number)
  end

  def phone=(number)
    self.phone_number = { number: number }
  end

  def merge_phone_numbers
    phone_numbers.reload.each do |phone_number|
      other_phone = phone_numbers.find do |pn|
        pn.id != phone_number.id &&
          pn == phone_number
      end
      next unless other_phone
      phone_number.merge(other_phone)
      merge_phone_numbers
      break
    end
  end

  def title=(value)
    value_with_trail = "#{value}."
    if Person::TITLES.include?(value_with_trail)
      super value_with_trail
    else
      super value
    end
  end

  def suffix=(value)
    value_with_trail = "#{value}."
    if Person::SUFFIXES.include?(value_with_trail)
      super value_with_trail
    else
      super value
    end
  end

  def profession=(value)
    self.occupation ||= value
  end

  def merge(other)
    Person.transaction(requires_new: true) do
      # This is necessary in case this is executed in a loop of merges which could cause the master_person
      # stored in memory to become out of date with what's in the database and cause an error.
      reload
      other.reload

      other.messages_sent.update_all(from_id: id)
      other.messages_received.update_all(to_id: id)

      %w(phone_numbers company_positions).each do |relationship|
        other.send(relationship.to_sym).each do |other_rel|
          next if send(relationship.to_sym).find { |rel| rel == other_rel }
          other_rel.update_column(:person_id, id)
        end
      end

      merge_phone_numbers

      # handle a few things separately to check for duplicates
      %w(twitter_accounts facebook_accounts linkedin_accounts
         google_accounts relay_accounts organization_accounts).each do |relationship|
        other.send(relationship).each do |record|
          next if send(relationship).where(person_id: id, remote_id: record.remote_id).any?
          record.update_attribute(:person_id, id)
        end
      end

      other.email_addresses.each do |email_address|
        next if email_addresses.find_by(email: email_address.email)
        if primary_email_address.present?
          # if there is already a primary email address on a person, we don't want to try to move the
          # loser's primary, which will override the winner's primary setting.
          email_address.update(person_id: id, primary: false)
        else
          email_address.update(person_id: id)
        end
      end

      other.pictures.each do |picture|
        picture.picture_of = self
        picture.save
      end

      # because we're in a transaction, we need to keep track of which relationships we've updated so
      # we don't create duplicates on the next part
      FamilyRelationship.where(related_person_id: other.id).find_each do |fr|
        next if FamilyRelationship.find_by(person_id: fr.person_id, related_person_id: id)
        fr.update_attributes(related_person_id: id)
      end

      FamilyRelationship.where(person_id: other.id).find_each do |fr|
        next if FamilyRelationship.where(related_person_id: fr.person_id, person_id: id)
        fr.update_attributes(person_id: id)
      end

      # Copy fields over updating any field that's blank on the winner
      [:first_name, :last_name, :legal_first_name, :birthday_month, :birthday_year, :birthday_day, :anniversary_month,
       :anniversary_year, :anniversary_day, :title, :suffix, :gender, :marital_status,
       :middle_name, :access_token].each do |field|
        next unless send(field).blank? && other.send(field).present?
        send("#{field}=".to_sym, other.send(field))
      end

      # Assume the winner has the nickname and the loser has the full name, and increment the times merged to
      # track which nicknames are useful and to add new nicknames over time.
      Nickname.increment_times_merged(other.first_name, first_name)

      # Save the master person sources for the winner to add after it (and usually its master person) are destroyed
      other_master_person_id = other.master_person.id
      other_master_person_sources = other.master_person.master_person_sources.pluck(:organization_id, :remote_id)

      ids = [id, other.id]
      DuplicateRecordPair.type(self.class).find_by(record_one_id: ids, record_two_id: ids)&.destroy

      other.reload
      other.destroy

      # Merge the master person records if they were different.
      Person.where(master_person_id: other_master_person_id).find_each do |person_same_master_other|
        person_same_master_other.update(master_person: master_person)
      end
      MasterPerson.find_by(id: other_master_person_id).try(:destroy) unless other_master_person_id == master_person_id
      other_master_person_sources.each do |organization_id, remote_id|
        master_person.master_person_sources.find_or_create_by(organization_id: organization_id, remote_id: remote_id)
      end
    end

    save(validate: false)
  end

  def self.clone(person)
    new_person = new(
      person.attributes.except(
        'id', 'access_token', 'created_at', 'current_sign_in_at', 'current_sign_in_ip', 'last_sign_in_at',
        'last_sign_in_ip', 'preferences', 'sign_in_count'
      )
    )
    person.email_addresses.each { |e| new_person.email = e.email }
    person.phone_numbers.each { |pn| new_person.phone_number = pn.attributes.slice(:number, :country_code, :location) }
    new_person.save(validate: false)
    new_person
  end

  def contact
    @contact ||= contacts.first
  end

  def contact_id
    contact.try(:id)
  end

  def to_person
    self
  end

  def birthday_year
    get_four_digit_year_from_value(attributes['birthday_year']) || placeholder_for_missing_year(:birthday)
  end

  def anniversary_year
    get_four_digit_year_from_value(attributes['anniversary_year']) || placeholder_for_missing_year(:anniversary)
  end

  def entity_attributes_to_push
    entity_attributes = super
    entity_attributes[:gender] = gender_entity_attribute
    entity_attributes.merge! authentication_attributes
    entity_attributes.merge! linked_identities_entity_attributes
  end

  private

  def gender_entity_attribute
    case gender
    when 'female', 'Female'
      'Female'
    when 'male', 'Male'
      'Male'
    else
      'Male'
    end
  end

  def authentication_attributes
    # Global Registry only allows one of each authentication type
    authentication = {}
    # If more than 1 key account, last wins
    key_accounts.each { |a| authentication[:key_guid] = a.remote_id }
    authentication[:facebook_uid] = facebook_account&.remote_id if facebook_account
    authentication.present? ? { authentication: authentication } : {}
  end

  def linked_identities_entity_attributes
    # Link account_number to siebel or peoplesoft if present
    account_number = donor_accounts.first&.account_number
    return {} unless account_number.present? && account_number.length > 5
    { account_number: account_number,
      linked_identities: {
        pshr: { account_number: account_number },
        siebel: { account_number: account_number }
      } }
  end

  def trigger_mail_chimp_syncs_to_relevant_contacts
    contacts.each(&:sync_with_mail_chimp)
  end

  def sync_with_mail_chimp_required?
    @mail_chimp_sync
  end

  def check_state_for_mail_chimp_sync
    @mail_chimp_sync = true if should_trigger_mail_chimp_sync?
  end

  def should_trigger_mail_chimp_sync?
    optout_enewsletter_changed?
  end

  def find_master_person
    self.master_person_id = MasterPerson.find_or_create_for_person(self).id unless master_person_id
  end

  def clean_up_master_person
    master_person.destroy if master_person && (master_person.people - [self]).blank?
  end

  def reject_duplicate_facebook_username_data(attributes_data)
    case attributes_data
    when Array
      reject_duplicate_facebook_usernames_from_data_array(attributes_data)
    when Hash
      reject_duplicate_facebook_usernames_from_data_array(attributes_data.values)
    end
  end

  def reject_duplicate_facebook_usernames_from_data_array(data_array)
    data_array = data_array.map(&:deep_symbolize_keys)
    persisted_records, new_records = data_array.partition { |attrs| attrs[:id].present? }

    new_records.each_with_object(persisted_records) do |new_record, records_to_keep|
      records_to_keep << new_record unless records_to_keep.any? { |record_to_keep| record_to_keep[:username] == new_record[:username] }
    end
  end

  # If the date has a day and a month but no year then we want to default the year to a particular value.
  # If day, month, and year are all nil then year should remain nil.
  def placeholder_for_missing_year(date_name)
    day_attribute_name = "#{date_name}_day"
    month_attribute_name = "#{date_name}_month"
    return unless send(day_attribute_name) && send(month_attribute_name)
    1900
  end
end
