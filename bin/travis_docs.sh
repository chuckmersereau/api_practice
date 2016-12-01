#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"

function doCompile {
  ./bin/rake docs:generate
}


# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" -o "$TEST_SUITE" != "1" ]; then
    echo "Skipping deploy"
    exit 0
fi

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Save some useful information
REPO="https://git@github.com/CruGlobal/mpdx_docs.git"
SHA=`git rev-parse --verify HEAD`

# Clone the existing gh-pages for this repo into docs/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
git clone $REPO docs_repo

# Run our compile script
doCompile
rm docs_repo/source/includes/_generated_examples.markdown
cp docs/api/_generated_examples.markdown docs_repo/source/includes/

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
git push $REPO $TARGET_BRANCH
