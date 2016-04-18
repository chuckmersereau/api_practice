# NOTE: If you run "bundle exec rake karma:run" on your local machine and it
# fails with a "Syntax error" message for coffeescript/js in a gem, what you
# need to do is run "bundle install --path vendor --without=production" which
# will package the gems locally for you and will allow karma to run correctly in
# the context of the Rails asset pipeline.

namespace :karma do
  task start: :environment do
    with_tmp_config :start
  end

  task run: :environment do
    with_tmp_config :start, '--single-run'
  end

  private

  def with_tmp_config(command, args = nil)
    `mkdir -p tmp`
    Tempfile.open('karma_unit.js', Rails.root.join('tmp')) do |f|
      f.write unit_js(application_spec_files)
      f.flush
      raise unless system "./node_modules/karma/bin/karma #{command} #{f.path} #{args}"
    end
  end

  def application_spec_files
    sprockets = Rails.application.assets
    sprockets.append_path Rails.root.join('spec/karma')
    Rails.application.assets.find_asset('application_spec.js').to_a.map { |e| e.pathname.to_s }
  end

  def unit_js(files)
    unit_js = File.open('spec/karma/config/unit.js', 'r').read
    unit_js.gsub 'APPLICATION_SPEC', "\"#{files.join("\",\n\"")}\""
  end
end
