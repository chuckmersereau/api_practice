[![Build Status](https://travis-ci.org/CruGlobal/mpdx.png?branch=master)](https://travis-ci.org/CruGlobal/mpdx)

MPDX API
========

MPDX is an online tool designed to help you maintain and improve your relationships with your ministry partners.

This repo sets up the API endpoint necessary for the app to work.

## Local Setup

### Requirements

* Ruby version corresponding to the version in file `.ruby-version`
* PostgreSQL
* Redis

On Mac OS you can use Homebrew to setup these requirements.

### Environment Variables

You might not need to setup any environment variables for local development, depending on the features you plan to work on. But if you do, you can make a `.env.local` file in your project root and add any local config variables you may need.

### Install Gems

We use a paid version of the sidekiq gem. In order to install our gem stack,
you will need to add the password to your gem config.
[Find them here](https://docs.google.com/a/cru.org/document/d/17RZH6MbGxtsrS3kLdOQlnXUFlg_q7fJoh1AfLwZBFz4)
(you will need to log in with a Cru email address).

Setup sidekiq credentials with this command (using the correct user and password):
```bash
$ bundle config gems.contribsys.com user:password
```

Then install gems:
```bash
$ bundle install
```

### Create Databases

Create, migrate, and seed your databases with:

```bash
$ bin/rake db:setup
```

### Start Server

Rails server:
```bash
$ bin/rails s
```

Sidekiq:
```bash
$ bundle exec sidekiq
```

### Login

Use a [TheKey.me](http://thekey.me/) or Relay account to login.

When you login for the first time you'll be asked to connect your user account to an organization. For dev purposes you can use the Toontown organization. To connect to Toontown you'll need to enter a username and password, please ask for it. Connecting to the Toontown org will allow your dev machine to import fake data for dev purposes.

After you login successfully the sidekiq process should begin importing your fake account data. If you don't see any data make sure that sidekiq is running without errors.


## Testing

There are four different test sets that we are running:

- Regular RSpec: `bin/rspec spec`
- Rubocop: `bin/rubocop -R`

### Rubocop

Run `bin/rubocop -D -R --auto-correct` to attempt auto-correction of your Rubocop offenses.


## Branches

### master

The master branch is deployed to production at [api.mpdx.org](https://api.mpdx.org/)

### staging

The staging branch is deployed to staging [stage.api.mpdx.org](https://stage.api.mpdx.org/), [Jenkins](http://jenkins.uscm.org/) will auto-deploy on successful builds.


## Issue Tracking, Bugs Reports, & Contributing

* Issues Tracking: [Cru Jira](https://jira.cru.org)
* Bug Reports: https://github.com/CruGlobal/mpdx/issues
* Want to Contribute? Read the Guide: https://github.com/CruGlobal/mpdx_api/blob/master/CONTRIBUTING.md


## LICENSE:

MIT License

Copyright (c) 2012

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
