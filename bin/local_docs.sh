#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

function doCompile {
  RAILS_ENV=test ./bin/rake mpdx:generate_docs
  # RAILS_ENV=test ./bin/rake docs:generate:ordered
}

# Run our compile script
doCompile

rm ../mpdx_staging_docs/source/includes/_account_lists.markdown
rm ../mpdx_staging_docs/source/includes/_appeals.markdown
rm ../mpdx_staging_docs/source/includes/_contacts.markdown
rm ../mpdx_staging_docs/source/includes/_people.markdown
rm ../mpdx_staging_docs/source/includes/_entities.markdown
rm ../mpdx_staging_docs/source/includes/_tasks.markdown
rm ../mpdx_staging_docs/source/includes/_user.markdown
rm ../mpdx_staging_docs/source/includes/_reports.markdown
rm ../mpdx_staging_docs/source/includes/_changelog.markdown

cp doc/api/account_lists_api/index.html.md ../mpdx_staging_docs/source/includes/_account_lists.markdown
cp doc/api/appeals_api/index.html.md ../mpdx_staging_docs/source/includes/_appeals.markdown
cp doc/api/contacts_api/index.html.md ../mpdx_staging_docs/source/includes/_contacts.markdown
cp doc/api/people_api/index.html.md ../mpdx_staging_docs/source/includes/_people.markdown
cp doc/api/entities/index.html.md ../mpdx_staging_docs/source/includes/_entities.markdown
cp doc/api/tasks_api/index.html.md ../mpdx_staging_docs/source/includes/_tasks.markdown
cp doc/api/user_api/index.html.md ../mpdx_staging_docs/source/includes/_user.markdown
cp doc/api/reports_api/index.html.md ../mpdx_staging_docs/source/includes/_reports.markdown

cp CHANGELOG.md ../mpdx_staging_docs/source/includes/_changelog.markdown
