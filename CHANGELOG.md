# MPDX API Changelog

This changelog covers what's changed in the MPDX APIs.

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

## 9 Feburary 2017
- added an API changelog
- updated contributing.md to suggest contribution to changelog
