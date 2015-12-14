if [ "$TEST_SUITE" = "1" ]
then
  npm install && bundle exec rake karma:run
else
  bundle exec rubocop
fi
