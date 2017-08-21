CONTROLLER_TO_SERIALIZER_LOOKUP = {
  'Api::V2::AccountLists::AnalyticsController' => 'AccountList::AnalyticsSerializer',
  'Api::V2::Contacts::AnalyticsController' => 'Contact::AnalyticsSerializer',
  'Api::V2::Contacts::DuplicatesController' => 'DuplicateRecordPairSerializer',
  'Api::V2::Contacts::MergesController' => 'ContactSerializer',
  'Api::V2::Contacts::People::DuplicatesController' => 'Person::DuplicateSerializer',
  'Api::V2::Contacts::People::MergesController' => 'PersonSerializer',
  'Api::V2::Contacts::ReferrersController' => 'ContactSerializer',
  'Api::V2::Reports::DonorCurrencyDonationsController' => 'Reports::DonorCurrencyDonationsSerializer',
  'Api::V2::Reports::ExpectedMonthlyTotalsController' => 'Reports::ExpectedMonthlyTotalsSerializer',
  'Api::V2::Reports::GoalProgressesController' => 'Reports::GoalProgressSerializer',
  'Api::V2::Reports::MonthlyGivingGraphsController' => 'Reports::MonthlyGivingGraphSerializer',
  'Api::V2::Reports::SalaryCurrencyDonationsController' => 'Reports::SalaryCurrencyDonationsSerializer',
  'Api::V2::Reports::YearDonationsController' => 'Reports::YearDonationsSerializer',
  'Api::V2::Tasks::AnalyticsController' => 'Task::AnalyticsSerializer'
}.freeze
