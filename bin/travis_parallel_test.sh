if [ "$TEST_SUITE" = "1" ]
then
  TEST_GROUPS=1,2
else
  TEST_GROUPS=3,4
fi

DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 4 \
  --only-group $TEST_GROUPS --group-by filesize --type rspec --verbose
