# rubocop:disable BlockNesting
class ContactFilter
  attr_accessor :contacts, :filters

  def initialize(filters = nil)
    @filters = filters || {}

    # strip extra spaces from filters
    @filters.map { |k, v| @filters[k] = v.strip if v.is_a?(String) }
  end

  def filter(contacts, account_list)
    @contacts = filtered_contacts = contacts

    if filters.present?
      if @filters[:ids].present?
        filtered_contacts = filtered_contacts.where('contacts.id' => @filters[:ids].split(','))
      end

      if @filters[:not_ids]
        filtered_contacts = filtered_contacts.where('contacts.id not in (?)', @filters[:not_ids])
      end

      if @filters[:tags].present? && @filters[:tags].first != ''
        filtered_contacts = filtered_contacts.tagged_with(@filters[:tags].split(','))
      end

      if @filters[:name_like]
        # See if they've typed a first and last name
        filtered_contacts = if @filters[:name_like].split(/\s+/).length > 1
                              filtered_contacts.where("concat(first_name,' ',last_name) like ? ", "%#{@filters[:name_like]}%")
                            else
                              filtered_contacts.where('first_name like :search OR last_name like :search',
                                                      search: "#{@filters[:name_like]}%")
                            end
      end

      filtered_contacts = city(filtered_contacts)
      filtered_contacts = church(filtered_contacts)
      filtered_contacts = state(filtered_contacts)
      filtered_contacts = region(filtered_contacts)
      filtered_contacts = metro_area(filtered_contacts)
      filtered_contacts = country(filtered_contacts)
      filtered_contacts = likely(filtered_contacts)
      filtered_contacts = status(filtered_contacts)
      filtered_contacts = referrer(filtered_contacts)
      filtered_contacts = newsletter(filtered_contacts)
      filtered_contacts = contact_name(filtered_contacts)
      filtered_contacts = timezone(filtered_contacts)
      filtered_contacts = pledge_currency(filtered_contacts, account_list)
      filtered_contacts = locale(filtered_contacts, account_list)
      filtered_contacts = related_task_action(filtered_contacts)
      filtered_contacts = appeal(filtered_contacts)
      filtered_contacts = contact_type(filtered_contacts)
      filtered_contacts = wildcard_search(filtered_contacts)
      filtered_contacts = pledge_freq(filtered_contacts)
      filtered_contacts = pledge_received(filtered_contacts)
      filtered_contacts = contact_info_email(filtered_contacts)
      filtered_contacts = contact_info_phone(filtered_contacts)
      filtered_contacts = contact_info_address(filtered_contacts)
      filtered_contacts = contact_info_facebook(filtered_contacts)
    end

    filtered_contacts
  end

  def city(filtered_contacts)
    if @filters[:city].present? && @filters[:city].first != ''
      filtered_contacts = filtered_contacts.where('addresses.city' => @filters[:city], 'addresses.historic' => @filters[:address_historic] || false)
                                           .includes(:addresses)
                                           .references('addresses')
    end
    filtered_contacts
  end

  def church(filtered_contacts)
    if @filters[:church].present? && @filters[:church].first != ''
      filtered_contacts = filtered_contacts.where('contacts.church_name' => @filters[:church])
    end
    filtered_contacts
  end

  def state(filtered_contacts)
    if @filters[:state].present? && @filters[:state].first != ''
      filtered_contacts = filtered_contacts.where('addresses.state' => @filters[:state], 'addresses.historic' => @filters[:address_historic] || false)
                                           .includes(:addresses)
                                           .references('addresses')
    end
    filtered_contacts
  end

  def region(filtered_contacts)
    if @filters[:region].present? && @filters[:region].first != ''
      filtered_contacts = filtered_contacts.where('addresses.region' => @filters[:region], 'addresses.historic' => @filters[:address_historic] || false)
                                           .includes(:addresses)
                                           .references('addresses')
    end
    filtered_contacts
  end

  def metro_area(filtered_contacts)
    if @filters[:metro_area].present? && @filters[:metro_area].first != ''
      filtered_contacts = filtered_contacts.where('addresses.metro_area' => @filters[:metro_area], 'addresses.historic' => @filters[:address_historic] || false)
                                           .includes(:addresses)
                                           .references('addresses')
    end
    filtered_contacts
  end

  def country(filtered_contacts)
    if @filters[:country].present? && @filters[:country].first != ''
      filtered_contacts = filtered_contacts.where('addresses.country' => @filters[:country],
                                                  'addresses.historic' => @filters[:address_historic] || false)
                                           .includes(:addresses)
                                           .references('addresses')
    end
    filtered_contacts
  end

  def likely(filtered_contacts)
    if @filters[:likely].present? && @filters[:likely].first != ''
      filtered_contacts = filtered_contacts.where(likely_to_give: @filters[:likely])
    end
    filtered_contacts
  end

  def status(filtered_contacts)
    if @filters[:status].present? && @filters[:status].first != ''
      unless @filters[:status].include? '*'
        if (@filters[:status].include? '') && !@filters[:status].include?('null')
          @filters[:status] << 'null'
        end

        if (@filters[:status].include? 'null') && !@filters[:status].include?('')
          @filters[:status] << ''
        end

        filtered_contacts = if @filters[:status].include? 'null'
                              filtered_contacts.where('status is null OR status in (?)', @filters[:status])
                            else
                              filtered_contacts.where(status: @filters[:status])
                            end
      end
    else
      filtered_contacts = filtered_contacts.active
    end
    filtered_contacts
  end

  def referrer(filtered_contacts)
    if @filters[:referrer].present? && @filters[:referrer].first != ''
      filtered_contacts = if @filters[:referrer].first == '*'
                            filtered_contacts.joins(:contact_referrals_to_me).where('contact_referrals.referred_by_id is not null').uniq
                          else
                            filtered_contacts.joins(:contact_referrals_to_me).where('contact_referrals.referred_by_id' => @filters[:referrer]).uniq
                          end
    end
    filtered_contacts
  end

  def newsletter(filtered_contacts)
    if @filters[:newsletter].present?
      filtered_contacts = case @filters[:newsletter]
                          when 'none'
                            filtered_contacts.where("send_newsletter is null OR send_newsletter = ''")
                          when 'address'
                            filtered_contacts.where(send_newsletter: %w(Physical Both))
                          when 'email'
                            filtered_contacts.where(send_newsletter: %w(Email Both))
                          else
                            filtered_contacts.where("send_newsletter is not null AND send_newsletter <> ''")
                          end
      filtered_contacts = filtered_contacts.uniq unless filtered_contacts.to_sql.include?('DISTINCT')
    end
    filtered_contacts
  end

  def contact_name(filtered_contacts)
    if @filters[:name].present?
      filtered_contacts = filtered_contacts.where('lower(contacts.name) like ?', "%#{@filters[:name].downcase}%")
    end
    filtered_contacts
  end

  def timezone(filtered_contacts)
    if @filters[:timezone].present? && @filters[:timezone].first != ''
      filtered_contacts = filtered_contacts.where('contacts.timezone' => @filters[:timezone])
    end
    filtered_contacts
  end

  def pledge_currency(filtered_contacts, account_list)
    if @filters[:pledge_currency].present? && @filters[:pledge_currency].first != ''
      filtered_contacts = if @filters[:pledge_currency].include?(account_list.default_currency)
                            filtered_contacts.where(pledge_currency: [@filters[:pledge_currency], '', nil])
                          else
                            filtered_contacts.where(pledge_currency: @filters[:pledge_currency])
                          end
    end
    filtered_contacts
  end

  def locale(filtered_contacts, _account_list)
    if @filters[:locale].present? && @filters[:locale].first != ''
      locales = @filters[:locale].map { |l| l == 'null' ? nil : l }
      filtered_contacts.where('contacts.locale' => locales)
    else
      filtered_contacts
    end
  end

  def related_task_action(filtered_contacts)
    if @filters[:relatedTaskAction].present? && @filters[:relatedTaskAction].first != ''
      if @filters[:relatedTaskAction].first == 'null'
        contacts_with_activities = filtered_contacts.where('activities.completed' => false)
                                                    .includes(:activities).map(&:id)
        filtered_contacts = filtered_contacts.where('contacts.id not in (?)', contacts_with_activities)
      else
        filtered_contacts = filtered_contacts.where('activities.activity_type' => @filters[:relatedTaskAction])
                                             .where('activities.completed' => false)
                                             .includes(:activities)
      end
    end
    filtered_contacts
  end

  def appeal(filtered_contacts)
    if @filters[:appeal].present? && @filters[:appeal].first != ''
      filtered_contacts = filtered_contacts.where('appeal_contacts.appeal_id' => @filters[:appeal]).includes(:appeals).uniq
    end
    filtered_contacts
  end

  def contact_type(filtered_contacts)
    case @filters[:contact_type]
    when 'person'
      filtered_contacts = filtered_contacts.people
    when 'company'
      filtered_contacts = filtered_contacts.companies
    end
    filtered_contacts
  end

  def wildcard_search(filtered_contacts)
    if @filters[:wildcard_search].present? && @filters[:wildcard_search] != 'null'
      if @filters[:wildcard_search].include?(',')
        last_name, first_name = @filters[:wildcard_search].split(',')
      else
        first_name, last_name = @filters[:wildcard_search].split
      end

      if first_name.present? && last_name.present?
        first_name = first_name.downcase.strip
        last_name = last_name.downcase.strip
        person_search = ' OR (lower(people.first_name) like :first_name AND lower(people.last_name) like :last_name)'
      else
        person_search = ''
      end

      filtered_contacts = filtered_contacts.where(
        'lower(email_addresses.email) like :search '\
          'OR lower(contacts.name) like :search '\
          'OR lower(donor_accounts.account_number) like :search '\
          'OR lower(phone_numbers.number) like :search' + person_search,
        search: "%#{@filters[:wildcard_search].downcase}%", first_name: first_name, last_name: last_name)
                                           .includes(people: :email_addresses)
                                           .references('email_addresses')
                                           .includes(:donor_accounts)
                                           .references('donor_accounts')
                                           .includes(people: :phone_numbers)
                                           .references('phone_numbers')
    end
    filtered_contacts
  end

  def pledge_freq(filtered_contacts)
    if @filters[:pledge_frequencies].present? && @filters[:pledge_frequencies].first != ''
      filtered_contacts = filtered_contacts.where(pledge_frequency: @filters[:pledge_frequencies])
    end
    filtered_contacts
  end

  def pledge_received(filtered_contacts)
    if @filters[:pledge_received].present?
      filtered_contacts = filtered_contacts.where(pledge_received: @filters[:pledge_received])
    end
    filtered_contacts
  end

  def contact_info_email(filtered_contacts)
    return filtered_contacts unless @filters[:contact_info_email].present?

    contacts_with_emails = @contacts.where.not(email_addresses: { email: nil })
                                    .where(email_addresses: { historic: false })
                                    .includes(people: :email_addresses)

    contacts_with_emails_ids = contacts_with_emails.pluck(:id)
    return filtered_contacts.where(id: contacts_with_emails_ids) if @filters[:contact_info_email] == 'Yes'
    return filtered_contacts if contacts_with_emails_ids.empty?
    filtered_contacts.where.not(id: contacts_with_emails_ids)
  end

  def contact_info_phone(filtered_contacts)
    filter_home_phone = @filters[:contact_info_phone]
    filter_mobile_phone = @filters[:contact_info_mobile]

    # set up contact id arrays
    if filter_home_phone.present?
      contacts_with_home_phone_ids = @contacts
                                     .where.not(phone_numbers: { number: nil })
                                     .where(phone_numbers: { historic: false, location: 'home' })
                                     .includes(people: :phone_numbers)
                                     .pluck(:id)
      filter_home_phone = '' if contacts_with_home_phone_ids.empty?
    end
    if filter_mobile_phone.present?
      contacts_with_mobile_phone_ids = @contacts
                                       .where.not(phone_numbers: { number: nil })
                                       .where(phone_numbers: { historic: false, location: 'mobile' })
                                       .includes(people: :phone_numbers)
                                       .pluck(:id)
      filter_mobile_phone = '' if contacts_with_mobile_phone_ids.empty?
    end

    # guard blank filters
    return filtered_contacts unless filter_home_phone.present? || filter_mobile_phone.present?

    # one but not the other
    if filter_home_phone.blank?
      result = if filter_mobile_phone == 'Yes'
                 filtered_contacts.where(id: contacts_with_mobile_phone_ids)
               else
                 filtered_contacts.where.not(id: contacts_with_mobile_phone_ids)
               end
      return result
    end
    if filter_mobile_phone.blank?
      result = if filter_home_phone == 'Yes'
                 filtered_contacts.where(id: contacts_with_home_phone_ids)
               else
                 filtered_contacts.where.not(id: contacts_with_home_phone_ids)
               end
      return result
    end

    # both filters present
    if filter_home_phone == 'Yes' && filter_mobile_phone == 'Yes'
      # & is intersection
      return filtered_contacts.where(id: contacts_with_mobile_phone_ids & contacts_with_home_phone_ids)
    end
    if filter_home_phone == 'Yes' && filter_mobile_phone == 'No'
      return filtered_contacts.where(id: contacts_with_home_phone_ids - contacts_with_mobile_phone_ids)
    end
    if filter_home_phone == 'No' && filter_mobile_phone == 'Yes'
      return filtered_contacts.where(id: contacts_with_mobile_phone_ids - contacts_with_home_phone_ids)
    end
    if filter_home_phone == 'No' && filter_mobile_phone == 'No'
      # | is union
      return filtered_contacts.where.not(id: contacts_with_mobile_phone_ids | contacts_with_home_phone_ids)
    end

    filtered_contacts
  end

  def contact_info_address(filtered_contacts)
    return filtered_contacts unless @filters[:contact_info_addr].present?

    contacts_with_addr = @contacts.where.not(addresses: { street: '' })
                                  .where(addresses: { historic: false })
                                  .includes(:addresses)

    contacts_with_addr_ids = contacts_with_addr.pluck(:id)
    return filtered_contacts.where(id: contacts_with_addr_ids) if @filters[:contact_info_addr] == 'Yes'
    return filtered_contacts if contacts_with_addr_ids.empty?
    filtered_contacts.where.not(id: contacts_with_addr_ids)
  end

  def contact_info_facebook(filtered_contacts)
    return filtered_contacts unless @filters[:contact_info_facebook].present?

    contacts_with_fb = filtered_contacts.where.not(person_facebook_accounts: { remote_id: nil })
                                        .includes(people: :facebook_account)
    return contacts_with_fb if @filters[:contact_info_facebook] == 'Yes'

    contacts_with_fb_ids = contacts_with_fb.pluck(:id)
    return filtered_contacts if contacts_with_fb_ids.empty?
    filtered_contacts.where.not(id: contacts_with_fb_ids)
  end
end
