#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in secrets.tar.enc -out secrets.tar -d
tar xvf secrets.tar

if [ "$TRAVIS_BRANCH" == "staging" ]; then
  SOURCE_BRANCH="staging"
  REPO="https://github.com/CruGlobal/mpdx_staging_docs.git"
  chmod 600 deploy_staging_key
  eval `ssh-agent -s`
  ssh-add deploy_staging_key
elif [ "$TRAVIS_BRANCH" == "master" ]; then
  SOURCE_BRANCH="master"
  REPO="https://github.com/CruGlobal/mpdx_docs.git"
  chmod 600 deploy_key
  eval `ssh-agent -s`
  ssh-add deploy_key
fi

function doCompile {
  ./bin/rake mpdx:generate_docs
}


# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" -o "$TEST_SUITE" != "1" ]; then
    echo "Skipping deploy"
    exit 0
fi

# Save some useful information
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Clone the existing gh-pages for this repo into docs/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
git clone $SSH_REPO docs_repo

# Run our compile script
doCompile

rm docs_repo/source/includes/_account_lists.markdown
rm docs_repo/source/includes/_appeals.markdown
rm docs_repo/source/includes/_contacts.markdown
rm docs_repo/source/includes/_people.markdown
rm docs_repo/source/includes/_entities.markdown
rm docs_repo/source/includes/_tasks.markdown
rm docs_repo/source/includes/_user.markdown
rm docs_repo/source/includes/_reports.markdown
rm docs_repo/source/includes/_changelog.markdown

cp doc/api/account_lists_api/index.html.md docs_repo/source/includes/_account_lists.markdown
cp doc/api/appeals_api/index.html.md docs_repo/source/includes/_appeals.markdown
cp doc/api/contacts_api/index.html.md docs_repo/source/includes/_contacts.markdown
cp doc/api/people_api/index.html.md docs_repo/source/includes/_people.markdown
cp doc/api/entities/index.html.md docs_repo/source/includes/_entities.markdown
cp doc/api/tasks_api/index.html.md docs_repo/source/includes/_tasks.markdown
cp doc/api/user_api/index.html.md docs_repo/source/includes/_user.markdown
cp doc/api/reports_api/index.html.md docs_repo/source/includes/_reports.markdown
cp CHANGELOG.md docs_repo/source/includes/_changelog.markdown

# Now let's go have some fun with the cloned repo
cd docs_repo
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if [ -z `git diff --exit-code` ]; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add .
git commit -m "Deploy to MPDX Docs: ${SHA}"

# Now that we're all set up, we can push.
git push $SSH_REPO master
