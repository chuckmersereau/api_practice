docker pull cruglobal/base-image-ruby-version-arg:2.3.0
docker build -t cruglobal/$PROJECT_NAME:$GIT_COMMIT-$BUILD_NUMBER .
