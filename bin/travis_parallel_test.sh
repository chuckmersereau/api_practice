if [ "$TEST_SUITE" = "1" ]
then
  TEST_GROUPS=1,2
elif [ "$TEST_SUITE" = "2" ]
then
  TEST_GROUPS=3,4
else
  TEST_GROUPS=5,6
fi

DISABLE_SPRING=1 bundle exec parallel_test spec/ -n 6 \
  --only-group $TEST_GROUPS --group-by filesize --type rspec --verbose
