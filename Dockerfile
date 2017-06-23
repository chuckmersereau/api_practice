FROM 056154071827.dkr.ecr.us-east-1.amazonaws.com/base-image-ruby-version-arg:2.3
MAINTAINER cru.org <wmd@cru.org>

ARG SIDEKIQ_CREDS
ARG RAILS_ENV=production

COPY supervisord-sidekiq.conf /etc/supervisor/supervisord-sidekiq.conf
COPY Gemfile Gemfile.lock ./
COPY engines /home/app/webapp/engines

RUN bundle config gems.contribsys.com $SIDEKIQ_CREDS
RUN bundle install --jobs 20 --retry 5 --path vendor
RUN bundle binstub puma sidekiq rake

COPY . ./

ARG DB_ENV_POSTGRESQL_USER
ARG DB_ENV_POSTGRESQL_PASS
ARG DB_PORT_5432_TCP_ADDR
ARG REDIS_PORT_6379_TCP_ADDR
ARG REDIS_PORT_6379_TCP_PORT
ARG SMTP_USER_NAME
ARG SMTP_PASSWORD
ARG SMTP_ADDRESS
ARG SMTP_AUTHENTICATION
ARG SMTP_ENABLE_STARTTLS_AUTO
ARG SMTP_PORT
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_BUCKET
ARG CLOUDINARY_CLOUD_NAME
ARG CLOUDINARY_API_KEY
ARG CLOUDINARY_API_SECRET
ARG GOOGLE_GEOCODER_KEY
ARG GOOGLE_GEOCODER_CLIENT
ARG GOOGLE_GEOCODER_CHANNEL
ARG LINKEDIN_KEY
ARG LINKEDIN_SECRET
ARG TWITTER_KEY
ARG TWITTER_SECRET
ARG FACEBOOK_KEY
ARG FACEBOOK_SECRET
ARG GOOGLE_KEY
ARG GOOGLE_SECRET
ARG PRAYER_LETTERS_CLIENT_ID
ARG PRAYER_LETTERS_CLIENT_SECRET
ARG PLS_CLIENT_ID
ARG PLS_CLIENT_SECRET
ARG SECRET_KEY_BASE
ARG WSAPI_KEY
ARG DISABLE_ROLLBAR=true

RUN bundle exec rake assets:clobber assets:precompile RAILS_ENV=production

## Run this last to make sure permissions are all correct
RUN mkdir -p /home/app/webapp/tmp /home/app/webapp/db /home/app/webapp/log /home/app/webapp/public/uploads && \
  chmod -R ugo+rw /home/app/webapp/tmp /home/app/webapp/db /home/app/webapp/log /home/app/webapp/public/uploads
