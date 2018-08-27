if [ "$TEST_SUITE" = "2" ]
then
  gem install bundler-audit && bundle audit check --update --ignore CVE-2018-1000544
fi
