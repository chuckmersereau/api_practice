# A sample Guardfile
# More info at https://github.com/guard/guard#readme

group :red_green_refactor, halt_on_fail: true do
  guard :livereload do
    watch(%r{app/views/.+\.(erb|haml|slim)})
    watch(%r{app/helpers/.+\.rb})
    watch(%r{public/.+\.(css|js|html)})
    watch(%r{config/locales/.+\.yml})
    watch(%r{(app|vendor)(/assets/\w+/(.+)\.(scss))}) { |m| "/assets/#{m[3]}.css" }
    watch(%r{(app|vendor)(/assets/\w+/(.+\.(js|html))).*}) { |m| "/assets/#{m[3]}" }
  end

  guard 'rspec', all_on_start: false, all_after_pass: false, failed_mode: :focus, cmd: 'bin/spring rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { 'spec' }

    # Rails example
    watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
    watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
    watch(%r{^spec/support/(.+)\.rb$})                  { 'spec' }
    watch('config/routes.rb')                           { 'spec/routing' }
    watch('app/controllers/application_controller.rb')  { 'spec/controllers' }
    # Capybara request specs
    watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }
  end

  guard :rubocop, all_on_start: false, cli: ['--format', 'clang', '--rails', '--auto-correct'] do
    watch(%r{.+\.rb$})
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end
