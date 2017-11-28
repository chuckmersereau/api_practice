$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'auth/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'auth'
  s.version     = Auth::VERSION
  s.authors     = ['Tataihono Nikora']
  s.email       = ['tataihono.nikora@cru.org']
  s.summary     = 'Implements OmniAuth for MPDX API'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'oauth2', '~> 1.2.0'
  s.add_dependency 'omniauth', '~> 1.3.1'
  s.add_dependency 'omniauth-google-oauth2', '~> 0.4.1'
  s.add_dependency 'omniauth-prayer-letters', '~> 0.0.3'
  s.add_dependency 'omniauth-mailchimp', '~> 1.2.0'
  s.add_dependency 'omniauth-donorhub', '~> 0.1.1'
  s.add_dependency 'sass-rails', '~> 5.0.1'
  s.add_dependency 'warden', '~> 1.2.3'

  s.add_development_dependency 'dotenv-rails', '~> 2.1.1'
  s.add_development_dependency 'rubocop', '~> 0.49.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
end
