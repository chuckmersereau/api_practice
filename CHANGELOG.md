# MPDX API Changelog

This changelog covers what's changed in the MPDX APIs.

## 31 March 2017
- Added converted_amount and converted_currency to donation objects returned by the API.
- Added turkish to list of language constants.
- Add missing attributes metro_area, region, remote_id, and seasonal to Address serialization
- CSV Import: Remove support for Contact Name, instead we'll require at least First Name, or Last Name
- CSV Import: Remove Referred By because it's not supported yet
- CSV Import: Auto generate a Contact Name based on first and last names

## 30 March 2017
- Added bulk create actions for contacts/tags and tasks/tags
- Added a way to bulk remove multiple tags from multiple records on the contacts/tags and tasks/tags endpoints
- Bulk contacts/tags and tasks/tags now work like any other bulk endpoint
- Enabled being able to set `X-HTTP-Method-Override` header to override the request method

## 29 March 2017
- Added updated_at as a filter for Contacts endpoint
- Added updated_at as a filter for Tasks endpoint

## 28 March 2017
- Added contact related filters to tasks endpoint
- User creation now works. Now when you try to authenticate with a valid theKey ticket, and the User doesn't exist - it will create them
    - One thing to note - the User will be returned _without_ any `Account List` information, unless they are part of the Cru-USA organization
- TNT imports user fields as tags
- TNT imports Campaigns, renamed from Appeals in v3.2

## 27 March 2017
- Updating TntImport::GroupTagsLoader to import from TNT v3.2
- Added TntImport::Xml service class to assist TNT imports

## 24 March 2017
- Added endpoint to update people without specifying a contact_id at PUT api/v2/contacts/people

## 23 March 2017
- Add sources to Constants endpoint
- "source" and "valid_values" attributes are now updatable on phone_numbers, email_addresses, and addresses

## 22 March 2017
- When adding a referral under a Contact, ie: `contacts_referred_by_me`, you are now **required** to provide a related `account_list` for each referral
- When Merging Account Lists, the Target Account List (ie: the account that remains after the merge) is now returned in the response body of a successful merge

## 21 March 2017
- The API will now return better 404 detail messages when unable to find a resource

## 20 March 2017
- Added a pledge endpoint to access pledges associated to an account_list ( /account_lists/pledges )
- Filters ending with `_id` now allow for comma-delimited ids to be sent
- Add CSV Import get, list, and update endpoints
- Added alert frequencies to the constants endpoint
- Add CSV Import constants to the constants endpoint

## 17 March 2017
- Sparse fieldsets enabled for contacts and people duplicates endpoints

## 15 March 2017
- Adjust attributes returned / required for Linkedin Accounts

## 14 March 2017
- Add `website` attribute to `Contact` objects
- Adjust Bulk Delete Tags endpoints (`api/v2/contacts/tags/bulk` and `api/v2/tasks/tags/bulk`)
- Allow for resource filtering, ie: `filter[contact_ids]`
- Adjust object format of Tag to be removed to better mirror `json:api`

## 10 March 2017
- Added a mailing csv export endpoint
- FacebookAccount on person endpoint is now accepting username and remote_id as opposed to url
- Person object will now have only one primary address at a time
- Removed donor_account presence validation on organization_id as requested by Mike
- Now displaying parent_contact for people objects under birthdays_this_week field of contacts analytics
- Added Google OAuth endpoint
- Added Prayer Letters OAuth endpoint

## 8 March 2017
- all filters accept comma separated items

## 7 March 2017
- constant_list now returning a complete currency object instead of a string
- person duplicates endpoint is now eliminating doubles
- conflict error returns the value of update_at in db to client

## 6 March 2017
- Added bulk create tasks endpoint

## 3 March 2017
- removed validation on start_at and dropped no_date field
- added fr-CA to language constants

## 1 March 2017
- Added ability to sort by start_at field in donations endpoint
- Added a delete donation endpoint
- Added the ability to include people, email_addresses and phone_number in tasks endpoint
- Removed the 'links' object from list endpoints

## 28 February 2017
- Added tasks to contacts endpoint

## 27 February 2017
- Added locale_display to User model preferences
- Added completed_at sorting param to tasks endpoint

## 25 February 2017
- Added a contacts bulk create endpoint
- Bulk endpoints now *require* an `id` to be provided for _every object within the sent data array for create and update requests_
    - Without such, a 409 will be returned
- Fixed some of the documentation for the bulk update endpoints for tasks and contacts

## 24 February 2017
- Added notification fields to activity_serializer

## 23 February 2017
- Added `updated_at` as a filterable attribute on the LIST endpoint for all database backed Resources
- Added sorting by `donation_date` to Account Lists > Donations > LIST
- Added filtering by `donation_date` with a date range, on Account Lists > Donations > LIST

## 22 February 2017
- changed the account_lists method in V2 controller to only filter when account_list_id is in list of permitted_filters
- reordered the list of contact options returned by the /contacts/filter
- changed contact_id filter to donor_account_id filter for donations endpoint
- fixed contact status and activity type filters to allow them to accept several params seperated by comma
- account_list analytics endpoint now accepts datetime range in proper iso8601 format
- account_list endpoint now accepts notification_preferences relationships
- Fixed bug with person endpoint that took place when a linkedin account relationship was provided

## 21 February 2017
- Accepts datetime range filters that match `YYYY-MM-DDThh:mm:ssZ..YYYY-MM-DDThh:mm:ssZ`
  - Use two periods `..` to denote an inclusive range
  - Use three periods `...` to denote an exclusive range
- Accepts date range filters that match `YYYY-MM-DD..YYYY-MM-DD`
  - Use two periods `..` to denote an inclusive range
  - Use three periods `...` to denote an exclusive range

## 20 February 2017
- Fixed sorting for cases when chained with filters
- Added account_list_id filter to contacts and people duplicates endpoints
- Added attributes to person_serializer
- Removed html error pages from public folder
- Contact_ids filter config is now returning contacts ordered by name and account_list_id is included with each.
- Added an endpoint for deleting a named tag from all tasks (`DELETE /tasks/tags/bulk`) @ardation
- Added an endpoint for deleting a named tag from all contacts (`DELETE /contacts/tags/bulk`) @ardation

## 17 February 2017
- Added a serializer for Organization
- Added a contact_id filter to Donations endpoint
- Fixed assigning a person to a Task comment

## 15 February 2017
- Changed mail_chimp_accounts controller to mail_chimp_account
- Added documentation for create action of account_lists#mail_chimp_account endpoint
- Attempted to fix the seeder_application_spec intermittent error

## 13 February 2017
- Nested Attributes with Included data can now be sent in POST/PATCH
- Activity Comments are now officially Comments

## 9 February 2017
- added an API changelog
- updated contributing.md to suggest contribution to changelog
