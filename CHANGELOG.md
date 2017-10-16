# MPDX API Changelog

This changelog covers what's changed in the MPDX APIs.

## 12 October 2017
- Added api/v2/reports/monthly_losses_graphs endpoint.

## 09 October 2017
- Added /api/v2/coaching/pledges endpoint.

## 6 October 2017
- appeals/appeal_contacts endpoint is now sortable by contact.name
- appeals/excluded_appeal_contacts endpoint is now sortable by contact.name
- pledges endpoint is now filterable by status

## 05 October 2017
- Added /api/v2/coaching/account_lists endpoint.
- Added /api/v2/coaching/contacts endpoint.

## 4 October 2017
- Added ability to sort by contact name field in pledges endpoint.
- Contact Status filter now returns contacts with no status when 'active' is in the list of parameter.
- Added assignable_location_hashes to list of constants returned by the '/api/v2/constants' endpoint.

## 3 October 2017
- convert pledge status booleans to enum

## 29 September 2017
- Added pledged_to_appeal filter to appeal/:id/appeal_contacts endpoint.

## 28 September 2017
- Add all person fields to the /user endpoint.

## 27 September 2017
- Removed Burmese, Vietnamese, Japanese and Persian to list available languages.

## 19 September 2017
- Added the /contacts/people endpoint to get and delete a person without the contact id.

## 11 September 2017
- Removed /api/v2/appeals/contacts endpoint.
- Added /api/v2/appeals/appeal_contacts endpoint.
- Added /api/v2/appeals/excluded_appeal_contacts endpoint.
- Upon a successful Account Reset (an admin function), the user is sent an
  email asking them to logout and log back into MPDX. A link to the logout
  route is provided in the email body.

## 8 September 2017
- The ACCEPT-LANGUAGE header can now be used to set the locale on each request.
  - Eg. 'ACCEPT-LANGUAGE: "fr-FR"'

## 5 September 2017
- Added active_mpd_start_at, active_mpd_finish_at, active_mpd_monthly_goal fields to account_list object.
- Added primary_appeal relationship to account_list object.
- Added fix-send-newsletter count to /api/v2/tools/analytics endpoint.

## 31 August 2017
- Breaking changes to the /api/v2/contacts/people/duplicates endpoints. Duplicates are now resources with uuids.

## 30 August 2017
- Added pledges_amount fields to appeal object.

## 29 August 2017
- Added a 'processed' field on the pledge object.
- Added an 'appeal_id' filter on the pledges endpoint.
- Add a new include to designation_accounts called balances showing historic balances

## 21 August 2017
- Breaking changes to the /api/v2/user endpoint. preferences[setup] now returns a string if the user is not setup correctly.

## 18 August 2017
- Added email_blacklist attribute to google_integrations.
- Breaking changes to the /api/v2/contacts/duplicates endpoints. Duplicates are now resources with uuids.

## 17 August 2017
- Moved appeals donations attribute into relationships.

## 08 August 2017
- Added pt-BR (brazilian portuguese) to the list of supported locales on the API.

## 28 July 2017
- Added filter[display_currency] to '/api/v2/reports/monthly_giving_graph' that changes the converted currency for the graph.

## 24 July 2017
- Expanded the search scope of wildcard_search under '/api/v2/tasks' endpoint to include associated comments and contacts.

## 21 July 2017
- Addresses, email addresses and phone numbers now can be edited when the source is 'TntImport'.

## 20 July 2017
- The '/admin/impersonation' endpoint now permits the search of impersonated users by email addresses.

## 13 July 2017
- Removed the '/api/v2/user/authentication' endpoint.

## 12 July 2017
- Added a pledge_frequency_hashes field to '/api/v2/constants' endpoint.

## 11 July 2017
- Added organization to relationships on designation account objects returned by the API.
- Gift Aid can now be opted out for specific contacts.
- Added a '/reports/donation_monthly_totals' endpoint.

## 06 July 2017
- Added the '/admin/impersonation' endpoint.

## 27 June 2017
- Tasks endpoint can now sort by multiple parameters.
- Sorting now allows specifying the NULLS sort order (FIRST or LAST).

## 26 June 2017
- Added contact name search to donor accounts endpoint.

## 20 June 2017
- CSV Import should support importing Referred By.

## 19 June 2017
- TNT import now allows to import Campaign information related to all manually added gifts.

## 13 June 2017
- Added parent_contacts field to person object.
  - That field contains the ids of contacts associated to the person object.

## 09 June 2017
- Added a tools analytics endpoint:
  - Gives the number of contacts, addresses, phone numbers and email addresses that
    need to be fixed by the user. It also gives a count of the number of duplicated contacts and people associated to him/her.

## 08 June 2017
- Tnt import: improve setting task completed status, and timezone parsing.

## 06 June 2017
- Added wildcard search filter on '/api/v2/contacts/people' endpoint.
- Added location to list of task attributes displayed on '/api/v2/tasks' endpoint.

## 05 June 2017
- Added Vietnamese, Ukrainian, Burmese and Polish to list of languages supported on the API side.

## 09 May 2017
- Added translated constant hashes to list of constants at '/api/v2/constants'.
  - 'activity_translated_hashes', 'assignable_likely_to_give_translated_hashes',
    'assignable_send_newsletter_translated_hashes' and 'status_translated_hashes' were added.
  - They contain hashes with the english and translated version of each constant.

## 08 May 2017
- DB Migrations: AddAmountCurrencyToPledges, AddAppealIdToPledges, CreatePledgeDonations, MigratePledgesDonationIdDataToJoinTable, RemoveDonationIdFromPledges
- Pledge now has many Donations (instead of belongs_to).
- Pledge now has an amount_currency.
- TNT Import parses dates according to the user's timezone.
- TNT Import now imports Pledges (called "Promises" in TNT).

## 05 May 2017
- Allow clients to apply merge the different filters together using an 'OR'. To do so add 'any_filter = true' to your list of filters.

## 04 May 2017
- Added 5 new filters.
  - Those are: gave_more_than_pledged, no_appeals, pledge_amount_increase_within, started_giving_within and
    stopped_giving_within. View documentation for details.
- Migration: Add is_organization to contacts
- TNT Import now imports Contact is_organization

## 01 May 2017
- Added updated_at filter to people.
- Allowing clients to set a foreign key to nil.
  - To do so just set "id: 'none'" for a belongs_to relationship
- Add "qa" Rails environment

## 28 April 2017
- Added batch endpoint at `POST /api/v2/batch`
  - It expects a JSON payload with a `requests` key that has an array of request objects. A request object needs to have a `method` key and a `path` key. It may also have a `body` key.
  - The response will be a JSON array of response objects. A response object has a `status` key, a `headers` key, and a `body` key.  The `body` is a string of the server response.
  - In addition to the `requests` key in the payload, you may also specify a `on_error` key which may be set to `CONTINUE`, or `ABORT`. `CONTINUE` is the default, and it will return a 200 no matter what, and give a response for every request, no matter if they errored or not. `ABORT` will end the batch request early if one of the requests fails. The batch response will have the status code of the failing request, and the response will include responses up to and including the errored request, but no more.
  - Some endpoints are unable to be used within a batch request. At this time, only bulk endpoints are disallowed from being used in a batch request.

## 26 April 2017
- Now allowing anyone invited to share an account to edit any of the account's resources on MPDX.
- Allowing reverse filters for any contacts or tasks filters.
    - To do so just add 'reverse_FILTER_NAME_HERE = true' to the filter hash.

## 25 April 2017
- Added /account_lists/invites/accept endpoint to allow users to accept an account list invite.

## 20 April 2017
- Added received_not_processed to pledges.
- Contact suggested_changes used to sometimes suggest a blank value for status, this was a bug that has been fixed.

## 18 April 2017
- Added direct deposit to contact endpoints.
- Updated translations and added it, th and id.
- Added a contact name_like filter.

## 13 April 2017
- Removed total_donations from all contact endpoints.
- Added api_class and help_email attributes to a new constant field called organizations_attributes.
- Added contact referrals relationships to contact serializer.
- Added people bulk endpoints.

## 11 April 2017
- Update Contact suggested_changes after an import.
- Added updated_in_db_at to all 409 Conflict error payloads.
- Permit override param on imports.

## 10 April 2017
- Allows the client not to specify a particular accept or content-type header on the contacts export endpoints.
- Added a late_by_90_days field to contacts analytics endpoint.

## 8 April 2017
- Add `mobile_alert_frequencies` to Constants.

## 7 April 2017
- Added a way to overwrite data on PATCH requests without providing an `updated_in_db_at` value.

## 6 April 2017
- Contacts Wildcard Search is now returning contacts where the value is in notes.
- Addresses are now returning the source_donor_account relationship.
- Contacts are now returning the primary_or_first_person relationship.

## 5 April 2017
- Added total_donation to donation detail
- Amount under donation endpoint is now just returning an amount without symbol

## 4 April 2017
- TNT Import now imports social media accounts.
- TNT Import now imports contact envelope_greeting.

## 3 April 2017
- Imports API now accepts comma delimited tag_list, instead of tags.

## 2 April 2017
- Added Russian, Arabic, German and Korean to list of languages supported on the API side.

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
