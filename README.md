[![Build Status](https://travis-ci.com/CruGlobal/mpdx_api.svg?token=uek23xg9pfmdzVvobNp3&branch=master)](https://travis-ci.com/CruGlobal/mpdx_api)
[![codecov](https://codecov.io/gh/CruGlobal/mpdx_api/branch/master/graph/badge.svg?token=pfc2BagYCd)](https://codecov.io/gh/CruGlobal/mpdx_api)


MPDX API
========

MPDX is an online tool designed to help you maintain and improve your relationships with your ministry partners.

This repo sets up the API endpoint necessary for the app to work.


## Local Setup

### Requirements

* Ruby version corresponding to the version in file `.ruby-version`
* PostgreSQL version 9.6
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
$ bin/rake db:create && bin/rake db:migrate && bin/rake db:seed
```

**Note:** This application uses a structure.sql file instead of the Rails schema.rb file, the rake tasks `db:setup` and `db:schema:load` are not supported.

### Start Server

Start Rails server:
```bash
$ bin/rails s
```

### Sidekiq

Many MPDX features rely on [Sidekiq](https://github.com/mperham/sidekiq/wiki) background jobs. Sidekiq requires Redis.

Start Sidekiq:
```bash
$ bundle exec sidekiq -C config/sidekiq_api.yml
```

Visit [localhost:3000/sidekiq](http://localhost:3000/sidekiq) to view the Sidekiq web UI.

The gem [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron) is used to schedule daily background jobs.

### API Authentication

[JSON Web Token](https://en.wikipedia.org/wiki/JSON_Web_Token) is used for authentication on the API. This is implemented with the [gem ruby-jwt](https://github.com/jwt/ruby-jwt).

You can generate a token for a particular user by using the `JsonWebToken` class like so:
```
JsonWebToken.encode(user_id: 1)
```
Therefore, when you're developing, you can quickly generate a token and send it in a curl request to the API by running a command like this:
```
curl "http://localhost:3000/api/v2/user" -H "Authorization: `rails runner 'print JsonWebToken.encode(user_id: 1)'`"
```

### Login

On the front-end, users use a [TheKey.me](http://thekey.me/) account to login. TheKey is a single-sign-on system used by Cru for authentication. TheKey is an implementation of [CAS](https://en.wikipedia.org/wiki/Central_Authentication_Service). For the purposes of MPDX API development you don't need to understand TheKey or install anything, you only need to create an account if you are logging into MPDX from the front-end.


## Testing

There are two different test sets that we are running:

- Regular RSpec: `bundle exec rspec`
- Rubocop: `bundle exec rubocop`

### Rubocop

Run `bundle exec rubocop -a` to attempt auto-correction of your Rubocop offenses.


## Branches

### master [![Build Status](https://travis-ci.com/CruGlobal/mpdx_api.svg?token=uek23xg9pfmdzVvobNp3&branch=master)](https://travis-ci.com/CruGlobal/mpdx_api) [![codecov](https://codecov.io/gh/CruGlobal/mpdx_api/branch/master/graph/badge.svg?token=pfc2BagYCd)](https://codecov.io/gh/CruGlobal/mpdx_api)

The master branch is deployed to production at [api.mpdx.org](https://api.mpdx.org/)

### staging [![Build Status](https://travis-ci.com/CruGlobal/mpdx_api.svg?token=uek23xg9pfmdzVvobNp3&branch=staging)](https://travis-ci.com/CruGlobal/mpdx_api) [![codecov](https://codecov.io/gh/CruGlobal/mpdx_api/branch/staging/graph/badge.svg?token=pfc2BagYCd)](https://codecov.io/gh/CruGlobal/mpdx_api)

The staging branch is deployed to staging [stage.api.mpdx.org](https://stage.api.mpdx.org/)


## Offline Devices Data Syncing with the API

### Created At & Updated At

To allow offline clients to create and update resources and to ensure that the created_at and updated_at fields of that resource reflects the exact time of its creation and update, clients can provide the created_at or updated_at fields at the time of syncing.

### Updated At In Db

To allow offline clients to later sync resources with the API without overwriting valid data, the API will require that the updated_in_db_at field (which should reflect the value of the updated_at field that was last returned from the server) be provided in text format for each resource updated through a PUT request. The API will verify that the provided updated_in_db_at field has the exact same value that is currently stored in the database and reject the update if that is not the case. This will ensure that a client doesn't overwrite a resource without being aware of that resource's latest data.


## Universal Unique IDentifiers (UUID)

To allow clients to generate identifiers from their side, UUIDs are used in this project at the controller level. At the model level though, we are still using integer ids to refer to db objects. Things are setup this way, because a db migration would have been to risky.


## Generators

### GRAIP Controller Generator

This allows someone to run:

```bash
rails generate graip:controller Api/v2/Contacts
```

And it will automatically generate a controller template,
controller spec, and acceptance spec for how controllers will be formatted for this project following paradigms from [Growing Rails Applications In Practice](https://pragprog.com/book/d-kegrap/growing-rails-applications-in-practice).

#### Resources:
- For examples of the controller and spec files - check out: [spec/support/generators/graip/controller/](spec/support/generators/graip/controller)
- The generator templates can be found in [lib/generators/graip/controller/templates](lib/generators/graip/controller/templates).
- For more information on how to use this generator, check out [lib/generators/graip/controller/USAGE](lib/generators/graip/controller/USAGE).

## Translation

For translation, we are using [gem gettext_i18n_rails](https://github.com/grosser/gettext_i18n_rails).

One thing to note is that to add a localized language set (eg. es-419) to MPDX API, you will have to create a folder using an underscore instead of a dash in the language code name (eg. es_419) and you will also have to add the localized language to the I18n.config.available_locales array defined at 'config/initializers/fast_gettext.rb'. 


## API Documentation

Public API documentation is available at [docs.mpdx.org](http://docs.mpdx.org/). This doc is automatically generated using the [gem rspec_api_documentation](https://github.com/zipmark/rspec_api_documentation).

Staging documentation is at [docs-stage.mpdx.org](http://docs-stage.mpdx.org/).

To generate all of the docs locally run `DOC_FORMAT=html bin/rake docs:generate`

To generate docs just for particular specs, run `DOC_FORMAT=html bin/rspec spec/acceptance/api/v2/path_to_my_spec.rb --format RspecApiDocumentation::ApiFormatter`

The html files will be created in a new directory named "doc".

**Please note:** the output format will be different than what is used on [docs.mpdx.org](http://docs.mpdx.org/), but you can use this to verify your spec is correct before pushing it.


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
