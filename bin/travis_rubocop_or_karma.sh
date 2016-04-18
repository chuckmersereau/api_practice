if [ "$TEST_SUITE" = "1" ]
then
  npm install && bundle exec rake karma:run && bundle exec rspec spec/ --tag js
else
  bundle exec rubocop
fi
