#!/bin/bash

set -eu

ARTIFACTS_DIR="/tmp/aws-hands-on-ci-cd/build/webhook"
DEPENDENCIES_DIR="$ARTIFACTS_DIR/dependencies/python"

mkdir -p $DEPENDENCIES_DIR
rm -rf $ARTIFACTS_DIR/dependencies.zip
rm -rf $ARTIFACTS_DIR/deployment.zip

cd "$(dirname "$0")"

echo "Building lambda dependencies zip..."
(
  pip3 install -r requirements.txt -t $DEPENDENCIES_DIR
  cd $DEPENDENCIES_DIR
  cd ..
  zip -rq $ARTIFACTS_DIR/dependencies.zip python
)

echo "Building lambda deployment zip..."
(
  cd src
  zip -r $ARTIFACTS_DIR/deployment.zip . -x "*__pycache__/*"
)

echo "Done"
