# This class makes a link between two currency codes
# It has three required values:
#   - alias_code: This is the currency code that is not currently in the system
#   - rate_api_code: This is the currency code that our exchange rate API gives us (should be in the system already)
#   - ratio: This is a transform value that will adjust the exchange rate of the aliased currency rate
#
# Once a record of this type is saved to the DB, next time CurrencyRatesFetcherWorker runs it will
# create duplicates of all of the rates with code: rate_api_code for the new alias_code.
class CurrencyAlias < ApplicationRecord
end
