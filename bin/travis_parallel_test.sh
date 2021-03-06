if [ "$TEST_SUITE" = "1" ]
then
  TEST_GROUPS=1,2
elif [ "$TEST_SUITE" = "2" ]
then
  TEST_GROUPS=3,4
elif [ "$TEST_SUITE" = "3" ]
then
  TEST_GROUPS=5,6
elif [ "$TEST_SUITE" = "4" ]
then
TEST_GROUPS=7,8
fi

DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 8 \
  --only-group $TEST_GROUPS --serialize-stdout --group-by filesize --type rspec --verbose
