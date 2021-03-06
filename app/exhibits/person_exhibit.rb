class PersonExhibit < DisplayCase::Exhibit
  include DisplayCase::ExhibitsHelper

  def self.applicable_to?(object)
    object.class.name == 'Person'
  end

  def age(now = Time.now.utc.to_date)
    return nil unless [birthday_day, birthday_month, birthday_year].all?(&:present?)
    now.year - birthday_year - (now.month > birthday_month || (now.month == birthday_month && now.day >= birthday_day) ? 0 : 1)
  end

  def avatar(size = :square)
    if primary_picture
      size_to_load = size
      size_to_load = :large if size == :large_square
      begin
        url = primary_picture.image.url(size_to_load)
        return url if url
      rescue StandardError
      end
    end
    if facebook_account&.remote_id.present?
      return "https://graph.facebook.com/#{facebook_account.remote_id}/picture?height=120&width=120" if size == :large_square
      return "https://graph.facebook.com/#{facebook_account.remote_id}/picture?type=#{size}"
    end

    url = if gender == 'female'
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

  def to_s
    [first_name, last_name].compact.join(' ')
  end

  def social?
    facebook_account || twitter_account || linkedin_account
  end

  def facebook_link
    return unless facebook_account
    @context.link_to('', facebook_account.url, target: '_blank', class: 'fa fa-facebook-square')
  end

  def twitter_link
    return unless twitter_account
    @context.link_to('', twitter_account.url, target: '_blank', class: 'fa fa-twitter-square')
  end

  def email_link
    return unless primary_email_address
    @context.mail_to(primary_email_address.to_s, '', class: 'fa fa-envelope')
  end
end
