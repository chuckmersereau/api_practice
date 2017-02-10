# GraphQL Types

* [ ] UserType
* [ ] TaskType
* [ ] ContactType
* [ ] AppealType
* [ ] AccountListType
* [ ] PersonOrganizationAccountType
* [ ] UserOptionType
* [ ] PersonKeyAccountType
* [ ] PersonGoogleAccountType
* [ ] TaskFilterType
* [ ] TagType
* [ ] TaskAnalyticsType
* [ ] BalancesReportType
* [ ] ExpectedMonthlyTotalsReportType
* [ ] GoalProgressReportType
* [ ] MonthlyGivingReportType
* [ ] YearDonationsReportType
* [ ] PersonType
* [ ] ContactFilterType
* [ ] ContactAnalyticsType
* [ ] AddressType
* [ ] ContactDuplicateType
* [ ] PersonDuplicateType
* [ ] EmailAddressType
* [ ] FacebookAccountType
* [ ] LinkedInAccountType
* [ ] PhoneNumberType
* [ ] FamilyRelationshipType
* [ ] TwitterAccountType
* [ ] PersonWebsiteType
* [ ] AccountListAnalyticsType
* [ ] DesignationAccountType
* [ ] DonationType
* [ ] DonorAccountType
* [ ] ImportType
* [ ] AccountListInviteType
* [ ] MailChimpAccountType
* [ ] NotificationPreferenceType
* [ ] NotificationType
* [ ] PrayerLettersAccountType

# GraphQL Root Query Fields

* [ ] `accountList($id: !ID)`
* [ ] `appeal($id: !ID)`
* [ ] `constants`
* [ ] `contact($id: !ID)`
* [ ] `task($id: !ID)`
* [ ] `user($id: !ID)`
* [ ] `me`
* [ ] `report($type: !REPORT_ENUM)`

# GraphQL Root Mutation Fields

* [ ] `updateAccountList($id: !ID, $accountList: !AccountListInputType)`
* [ ] `createAppeal($appeal: !AppealInputType)`
* [ ] `updateAppeal($id: !ID, $appeal: !AppealInputType)`
* [ ] `deleteAppeal($id: !ID)`
* [ ] `createContact($contact: !ContactInputType)`
* [ ] `updateContact($id: !ID, $contact: !ContactInputType)`
* [ ] `deleteContact($id: !ID)`
* [ ] `createTask($task: !TaskInputType)`
* [ ] `updateTask($id: !ID, $task: !TaskInputType)`
* [ ] `deleteTask($id: !ID)`
* [ ] `updateUser($id: !ID, $user: !UserInputType)`
 ... there will be a pretty good amount of these.
