if [ "$TEST_SUITE" = "1" ]
then
  bundle exec rake karma:run && bundle exec rspec spec/ --tag js
else
  bundle exec rubocop && ./node_modules/.bin/eslint app/assets/javascripts
fi
