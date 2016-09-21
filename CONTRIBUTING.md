## Contributing

This is a guide to contributing to MPDX. It should walk you through the
major steps to contributing code to the project.

### 1. Create an Issue on GitHub

The first step to contributing to MPDX is creating a ticket in our
[ticketing system on GitHub](https://github.com/CruGlobal/mpdx/issues).
Please take a second to search for the issue or feature before creating a new one.

All bug fixes should have a ticket. This makes it easy for everyone
to discuss the code and know if a fix is already in progress for an issue.


### 2. Fork & Create a Feature Branch

The next step is to fork MPDX (if you haven't already done so) and
create a new git branch based on the feature or issue you're working on. Please
use a descriptive name for your branch.

For example a great branch name would be (where issue #325 is the ticket you're
working on):

    $> git checkout -b 325-add-japanese-translations


### 3. Follow setup steps in README.md

The readme contains requirements and steps for setting up your local development environment.

If something in the readme is wrong or missing please submit an issue or PR to help fix it!

https://github.com/CruGlobal/mpdx/blob/master/README.md


### 4. Get the test suite running

MPDX is a tool that many people rely on for managing their partner
relationships in their production applications. Bugs are not cool. Although we're not perfect,
we pride ourselves on writing well tested code. I hope you do too :)

MPDX uses rspec for it's test suite.

Most of the tests can be run with this command, see the readme for more details:

    $> bin/rspec spec

MPDX also includes the `guard` gem, so if you like continuous testing during development, run:

    $> bundle exec guard


### 5. Add an entry to /etc/hosts

Several callback services (including facebook and CAS) like to have a real hostname
to redirect to. To work with those we recommend that you create an entry in your `hosts`
file for local.mpdx.org like this:

`127.0.0.1 local.mpdx.org`

You might have to reboot after editing /etc/hosts before your computer picks up on it.


### 6. View your changes in a Rails application

MPDX is meant to be used by humans, not cucumbers. So make sure to take
a look at your changes in a browser (preferably a few browsers if you made view
changes).

To boot up a test rails application, use:

    $> bin/rails s

You should be able to open `http://localhost:3000/` and view a test
environment.

Run:

`bin/rake organizations:fetch`


### 7. Make a pull request

At this point, you should switch back to your master branch and make sure it's
up to date with MPDX's master branch. If there were any changes, you
should rebase your feature branch and make sure that it will merge correctly. If
there are any merge conflicts, your pull request will not be merged in.

Now push your changes up to your feature branch on GitHub and make a pull request!
We will pull your changes, run the test suite, review the code and merge it in.


