# We run the build in two parallel workers with TEST_SUITE=1 and TEST_SUITE=2
# Each build runs either rubocop or karma and then half of the specs
# We also run two tests groups per worker since each worker gets 1.5 cores


if [ $TEST_SUITE = 1 ]
then
  PHANTOMJS_CDNURL=https://bitbucket.org/ariya/phantomjs/downloads npm install
  bundle exec rake karma:run
  TEST_GROUPS=1,2
else
  bundle exec rubocop
  TEST_GROUPS=3,4
fi

DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 4 \
  --only-group $TEST_GROUPS --group-by filesize --type rspec

bundle exec rake coveralls:push
