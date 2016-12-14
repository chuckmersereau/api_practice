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
$ bin/rake db:create && bin/rake db:migrate && bin/rake db:seed
```

This application uses a structure.sql file instead of the Rails schema.rb file, the rake tasks `db:setup` and `db:schema:load` are not supported.

### Start Server

Rails server:
```bash
$ bin/rails s
```

Sidekiq:
```bash
$ bundle exec sidekiq
```

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

### master

The master branch is deployed to production at [api.mpdx.org](https://api.mpdx.org/)

### staging

The staging branch is deployed to staging [stage.api.mpdx.org](https://stage.api.mpdx.org/), [Jenkins](http://jenkins.uscm.org/) will auto-deploy on successful builds.

## Generators

### GRAIP Controller Generator

This allows someone to run:

```bash
rails generate graip:controller Api/v2/Contacts
```

And it will automatically generate a controller template,
controller spec, and acceptance spec for how controllers will be formatted for this project following paradigms from [Growing Rails Applications In Practice](https://pragprog.com/book/d-kegrap/growing-rails-applications-in-practice).

## Universal Unique Identifiers (UUID)

To allow clients to generate identifiers from their side, UUIDs are used in this project at the controller level. At the model level though, we are still using integer ids to refer to db objects. Things are setup this way, because a db migration would have been to risky.

#### Resources:
- For examples of the controller and spec files - check out: [spec/support/generators/graip/controller/](spec/support/generators/graip/controller)
- The generator templates can be found in [lib/generators/graip/controller/templates](lib/generators/graip/controller/templates).
- For more information on how to use this generator, check out [lib/generators/graip/controller/USAGE](lib/generators/graip/controller/USAGE).

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
