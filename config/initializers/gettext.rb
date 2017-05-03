require 'gettext_i18n_rails/string_interpolate_fix'
FastGettext.add_text_domain 'mpdx', path: 'locale', type: :po, report_warning: false
FastGettext.default_text_domain = 'mpdx'
FastGettext.default_available_locales = ['en-US','de','frFR', 'frCA', 'es', 'en', 'es419', 'it', 'ko', 'ru', 'id', 'ar', 'zhHANSCH', 'tr', 'th']
GettextI18nRails.translations_are_html_safe = true
