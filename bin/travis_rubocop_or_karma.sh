if [ "$TEST_SUITE" = "1" ]
then
  bundle exec rubocop
else
  npm install && bundle exec rake karma:run
fi
