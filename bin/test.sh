export RAILS_ENV=test && \
  bin/rake db:drop db:create db:structure:load && \
  bin/rspec spec
