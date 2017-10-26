#!/bin/bash

docker build \
    --build-arg SIDEKIQ_CREDS=$SIDEKIQ_CREDS \
    --build-arg DB_ENV_POSTGRESQL_USER=$DB_ENV_POSTGRESQL_USER \
    --build-arg DB_ENV_POSTGRESQL_PASS=$DB_ENV_POSTGRESQL_PASS \
    --build-arg DB_PORT_5432_TCP_ADDR=$DB_PORT_5432_TCP_ADDR \
    --build-arg REDIS_PORT_6379_TCP_ADDR=$REDIS_PORT_6379_TCP_ADDR \
    --build-arg REDIS_PORT_6379_TCP_PORT=$REDIS_PORT_6379_TCP_PORT \
    --build-arg SMTP_USER_NAME=$SMTP_USER_NAME \
    --build-arg SMTP_PASSWORD=$SMTP_PASSWORD \
    --build-arg SMTP_ADDRESS=$SMTP_ADDRESS \
    --build-arg SMTP_AUTHENTICATION=$SMTP_AUTHENTICATION \
    --build-arg SMTP_ENABLE_STARTTLS_AUTO=$SMTP_ENABLE_STARTTLS_AUTO \
    --build-arg SMTP_PORT=$SMTP_PORT \
    --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --build-arg AWS_BUCKET=$AWS_BUCKET \
    --build-arg CLOUDINARY_CLOUD_NAME=$CLOUDINARY_CLOUD_NAME \
    --build-arg CLOUDINARY_API_KEY=$CLOUDINARY_API_KEY \
    --build-arg CLOUDINARY_API_SECRET=$CLOUDINARY_API_SECRET \
    --build-arg GOOGLE_GEOCODER_KEY=$GOOGLE_GEOCODER_KEY \
    --build-arg GOOGLE_GEOCODER_CLIENT=$GOOGLE_GEOCODER_CLIENT \
    --build-arg GOOGLE_GEOCODER_CHANNEL=$GOOGLE_GEOCODER_CHANNEL \
    --build-arg LINKEDIN_KEY=$LINKEDIN_KEY \
    --build-arg LINKEDIN_SECRET=$LINKEDIN_SECRET \
    --build-arg TWITTER_KEY=$TWITTER_KEY \
    --build-arg TWITTER_SECRET=$TWITTER_SECRET \
    --build-arg FACEBOOK_KEY=$FACEBOOK_KEY \
    --build-arg FACEBOOK_SECRET=$FACEBOOK_SECRET \
    --build-arg GOOGLE_KEY=$GOOGLE_KEY \
    --build-arg GOOGLE_SECRET=$GOOGLE_SECRET \
    --build-arg PRAYER_LETTERS_CLIENT_ID=$PRAYER_LETTERS_CLIENT_ID \
    --build-arg PRAYER_LETTERS_CLIENT_SECRET=$PRAYER_LETTERS_CLIENT_SECRET \
    --build-arg PLS_CLIENT_ID=$PLS_CLIENT_ID \
    --build-arg PLS_CLIENT_SECRET=$PLS_CLIENT_SECRET \
    --build-arg SECRET_KEY_BASE=$SECRET_KEY_BASE \
    --build-arg WSAPI_KEY=$WSAPI_KEY \
    -t 056154071827.dkr.ecr.us-east-1.amazonaws.com/$PROJECT_NAME:$ENVIRONMENT-$BUILD_NUMBER .
rc=$?

if [ $rc -ne 0 ]; then
  echo -e "Docker build failed"
  exit $rc
fi
