if [ "$TEST_SUITE" = "1" ]
then
  TEST_GROUPS=1,2
elif [ "$TEST_SUITE" = "2" ]
then
  TEST_GROUPS=3,4
elif [ "$TEST_SUITE" = "3" ]
then
  TEST_GROUPS=5,6
fi

if [ "$TEST_SUITE" != "5" ]
then
  DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 6 \
    --only-group $TEST_GROUPS --group-by filesize --type rspec --verbose
fi
