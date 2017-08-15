require 'gettext_i18n_rails/string_interpolate_fix'
text_domain = FastGettext.add_text_domain 'mpdx', path: 'locale', type: :po, report_warning: false
FastGettext.default_text_domain = 'mpdx'
I18n.config.available_locales = ['en', 'en-US','de','fr-FR', 'fr-CA', 'en', 'es-419', 'it', 'ko', 'pt-BR', 'ru', 'id', 'ar', 'zh-HANS-CH', 'tr', 'th', 'hy']
FastGettext.default_available_locales = I18n.config.available_locales.map{ |locale| locale.to_s.tr('-', '_') }
GettextI18nRails.translations_are_html_safe = true

# Overwrite the find_files_in_locale_folders method to not check the locale with the limiting REGEX before fetching the file.module FastGettext.
# We need this for locales like es-419 which the REGEX check would prevent from being loaded.
module FastGettext
  module TranslationRepository
    class Base
      def find_files_in_locale_folders(relative_file_path, path)
        path ||= "locale"
        raise "path #{path} could not be found!" unless File.exist?(path)

        @files = {}
        Dir[File.join(path,'*')].each do |locale_folder|
          file = File.join(locale_folder,relative_file_path).untaint
          next unless File.exist? file
          locale = File.basename(locale_folder)
          @files[locale] = yield(locale,file)
        end
      end
    end
  end
end

text_domain.reload # We are reloading the locale files here since we want loading to take place using the above code.
