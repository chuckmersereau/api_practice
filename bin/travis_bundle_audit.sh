if [ "$TEST_SUITE" = "2" ]
then
  gem install bundler-audit && bundle audit check --update
fi
