set -e

# Shorten the commit hash to 6 characters
export COMMIT=${TRAVIS_COMMIT::6}

# Prevents TRAVIS_BRANCH from causing problems on pull requests.
if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    export BRANCH=$TRAVIS_BRANCH
else
    export BRANCH=$TRAVIS_PULL_REQUEST_BRANCH
fi

export NAME=$(basename $PWD | cut -d'-' -f2)
export REPO=$DOCKER_USER/$NAME

if [[ $BRANCH == "master" ]]; then
    export TAG="latest"
else
    export TAG=$BRANCH
fi

export DOCKER_TAG=$REPO:$COMMIT

echo -e "
COMMIT: $COMMIT
BRANCH: $BRANCH
NAME: $NAME
REPO: $REPO
TAG: $TAG
DOCKER_TAG: $DOCKER_TAG
"

set +e
