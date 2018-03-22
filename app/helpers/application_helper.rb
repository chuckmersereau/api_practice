module ApplicationHelper
  include DisplayCase::ExhibitsHelper
  include LocalizationHelper

  def auth_link(provider)
    if current_user.send("#{provider}_accounts".to_sym).empty?
      prompt = _('Add an Account')
    else
      prompt = _('Add another Account') unless "Person::#{provider.camelcase}Account".constantize.one_per_user?
    end
    button_class = 'btn btn-secondary btn-xs'
    return unless prompt
    if provider == 'organization'
      link_to(prompt, '#', class: button_class, data: { behavior: 'add_org_account' })
    else
      link_to(prompt, "/auth/#{provider}", class: button_class)
    end
  end

  def link_to_clear_contact_filters(f)
    link_to(f, contacts_path(clear_filter: true))
  end

  def tip(tip, options = {})
    tag('span', class: 'qtip', title: tip, style: options[:style])
  end

  def spinner(options = {})
    id = options[:extra] ? "spinner_#{options[:extra]}" : 'spinner'
    style = options[:visible] ? '' : 'display:none'
    image_tag('spinner.gif', id: id, style: style, class: 'spinner')
  end

  def l(date, options = {})
    options[:format] ||= :date_time
    date = date.to_datetime unless date.class == Date || date.class == DateTime
    if date.class == Date
      date = date.to_datetime.localize(FastGettext.locale).to_date
    else
      date = Time.zone.utc_to_local(date)
      date = date.to_datetime.localize(FastGettext.locale)
    end

    if [:full, :long, :medium, :short].include?(options[:format])
      date.send("to_#{options[:format]}_s".to_sym)
    else
      case options[:format]
      when :month_abbrv
        date.to_s(format: 'MMM')
      when :date_time
        date.to_short_s
      else
        date.to_s(format: options[:format])
      end
    end
  end

  def calendar_date_select_tag(name, value = nil, options = {})
    options['data-calendar-jquery'] = true
    options['id'] = ''
    options['style'] = 'width:100px;'
    # options.merge!('readonly' => '')
    value = if value.is_a?(Time) || value.is_a?(DateTime)
              value.to_date.to_s(:db)
            elsif value.is_a?(Date)
              value.to_s(:db)
            else
              value
            end
    text_field_tag(name, value, options)
  end

  def currency_select
    hash = {}

    # show account default currency first
    default = current_account_list.default_currency
    hash[currency_code_and_symbol(default)] = default

    TwitterCldr::Shared::Currencies.currency_codes.each do |code|
      hash[currency_code_and_symbol(code)] = code
    end
    hash
  end

  def currency_code_and_symbol(code)
    code + ' (' + currency_symbol(code) + ')'
  end
end
