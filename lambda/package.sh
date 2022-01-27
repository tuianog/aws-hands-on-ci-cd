#!/bin/bash

# Example of run:
# > DEPLOY_PROJECT_NAME=aws-hands-on-ci-cd-project ./package.sh

set -eu

ARTIFACTS_DIR="/tmp/$DEPLOY_PROJECT_NAME/build/"
DEPENDENCIES_DIR="$ARTIFACTS_DIR/dependencies/python"

mkdir -p $DEPENDENCIES_DIR

cd "$(dirname "$0")"

echo "Building lambda dependencies zip..."
(
  pip3 install -r requirements.txt -t $DEPENDENCIES_DIR
  cd $ARTIFACTS_DIR/dependencies
  zip -rq $ARTIFACTS_DIR/dependencies.zip python
)

echo "Building lambda deployment zip..."
(
  cd src
  zip -r $ARTIFACTS_DIR/deployment.zip . -x "*__pycache__/*"
)

echo "Done"
