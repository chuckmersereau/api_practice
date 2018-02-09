class ContactExhibit < DisplayCase::Exhibit
  include DisplayCase::ExhibitsHelper
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  # Use ||= to avoid "warning: already initialized contant" for specs
  TABS ||= {
    'details' => _('Details'),
    'tasks' => _('Tasks'),
    'history' => _('History'),
    'referrals' => _('Referrals'),
    'notes' => _('Notes')
  }.freeze

  def self.applicable_to?(object)
    object.class.name == 'Contact'
  end

  def location
    [address.city, address.state, address.country].select(&:present?).join(', ') if address
  end

  def website
    if to_model.website.present?
      url = to_model.website.include?('http') ? to_model.website : 'http://' + to_model.website
      @context.link_to(@context.truncate(url, length: 30), url, target: '_blank')
    else
      ''
    end
  end

  def pledge_frequency
    Contact.pledge_frequencies[to_model.pledge_frequency || 1.0]
  end

  def avatar(size = :square)
    url = get_mpdx_picture_url_if_available(size)

    url ||= get_facebook_picture_url_if_available(size)

    url ||= get_google_plus_url_if_available(size)

    url || default_image_url_by_gender
  end

  def pledge_amount_formatter
    proc { |pledge| format_pledge_amount(pledge) }
  end

  def format_pledge_amount(pledge)
    return if pledge.blank?
    precision = whole_number?(pledge) ? 0 : 2
    if account_list.multi_currency?
      number_with_precision(pledge, precision: precision)
    else
      number_to_currency(pledge, precision: precision)
    end
  end

  def notes_saved_at
    return '' unless to_model.notes_saved_at
    l(to_model.notes_saved_at.to_datetime, format: :medium)
  end

  def donor_ids
    donor_accounts.map(&:account_number).join(', ')
  end

  def to_s
    name
  end

  def send_newsletter_error
    missing_address = !mailing_address.id
    missing_email_address = people.joins(:email_addresses).blank?

    if send_newsletter == 'Both' && missing_address && missing_email_address
      _('No mailing address or email addess on file')
    elsif (send_newsletter == 'Physical' || send_newsletter == 'Both') && missing_address
      _('No mailing address on file')
    elsif (send_newsletter == 'Email' || send_newsletter == 'Both') && missing_email_address
      _('No email addess on file')
    end
  end

  def csv_country
    mailing_address.csv_country(account_list.home_country)
  end

  def address_block
    "#{envelope_greeting}\n#{mailing_address.to_snail.gsub("\r\n", "\n")}"
  end

  private

  def get_mpdx_picture_url_if_available(size)
    picture = primary_or_first_person.primary_picture

    picture&.image&.url(size)
  end

  def get_facebook_picture_url_if_available(size)
    fb_account = primary_or_first_person.facebook_account

    if fb_account&.remote_id.present?
      return "https://graph.facebook.com/#{fb_account.remote_id}/picture?height=120&width=120" if size == :large_square
      "https://graph.facebook.com/#{fb_account.remote_id}/picture?type=#{size}"
    end
  end

  def get_google_plus_url_if_available(size)
    return unless relevant_google_plus_profile_picture_url

    "#{relevant_google_plus_profile_picture_url}?size=#{size_in_pixels(size)}"
  end

  def size_in_pixels(size)
    case size
    when :small_square
      100
    when :square
      200
    when :large_square
      300
    else
      200
    end
  end

  def relevant_google_plus_profile_picture_url
    primary_or_first_person&.primary_email_address&.google_plus_account&.profile_picture_link
  end

  def default_image_url_by_gender
    url = if primary_or_first_person.gender == 'female'
            ActionController::Base.helpers.image_url('avatar_f.png')
          else
            ActionController::Base.helpers.image_url('avatar.png')
          end

    if url.start_with?('/')
      root_url = 'https://mpdx.org'
      url = URI.join(root_url, url).to_s
    end

    url
  end

  def whole_number?(number)
    (number.to_f % 1).zero?
  end
end
