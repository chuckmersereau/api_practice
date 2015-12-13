# We run the build in two parallel workers with TEST_SUITE=1 and TEST_SUITE=2
# Each build runs either rubocop or karma and then half of the specs
# We also run two tests groups per worker since each worker gets 1.5 cores

rubocop_or_karma() {
  if [ "$TEST_SUITE" = "1" ]
  then
    bundle exec rubocop
  else
    npm install && bundle exec rake karma:run
  fi
}

parallel_test() {
  if [ "$TEST_SUITE" = "1" ]
  then
    TEST_GROUPS=1,2
  else
    TEST_GROUPS=3,4
  fi

  DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 4 \
    --only-group $TEST_GROUPS --group-by filesize --type rspec
}

rubocop_or_karma && parallel_test && bundle exec rake coveralls:push
