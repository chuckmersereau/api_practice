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

  def referrer_links
    referrals_to_me.map { |r| @context.link_to(exhibit(r, @context), r) }.join(', ').html_safe
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

  def contact_info
    people.order('contact_people.primary::int desc').references(:contact_people).map do |p|
      person_exhibit = exhibit(p, @context)
      phone_and_email_exhibits = [person_exhibit.phone_number, person_exhibit.email].compact.map { |e| exhibit(e, @context) }.join('<br />')
      [@context.link_to(person_exhibit, @context.contact_person_path(to_model, p)), phone_and_email_exhibits].select(&:present?).join(':<br />')
    end.join('<br />').html_safe
  end

  def pledge_frequency
    Contact.pledge_frequencies[to_model.pledge_frequency || 1.0]
  end

  def avatar(size = :square)
    if (picture = primary_or_first_person.primary_picture) && picture.image.url(size)
      picture.image.url(size)
    else
      fb = primary_or_first_person.facebook_account
      if fb && fb.remote_id.present?
        return "https://graph.facebook.com/#{fb.remote_id}/picture?height=120&width=120" if size == :large_square
        return "https://graph.facebook.com/#{fb.remote_id}/picture?type=#{size}"
      end

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

  def tag_links
    tags.map do |tag|
      @context.link_to(tag, @context.params.except(:action, :controller, :id).merge(action: :index, filters: { tags: tag.name }), class: 'tag')
    end.join(' ').html_safe
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

  private

  def whole_number?(number)
    (number.to_f % 1).zero?
  end
end
