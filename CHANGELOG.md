# MPDX API Changelog

This changelog covers what's changed in the MPDX APIs.

## 28 February 2017
- Added tasks to contact_serializer

## 27 February 2017
- Added locale_display to User model preferences
- Added completed_at sorting param to tasks endpoint

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
