#!/bin/bash

# Build project zip and push to S3 on the same script
# Use this script to upload master.zip to bucket to trigger pipeline
# Set the environmental variables accordingly; otherwise, fallback values will be used
# Example: AWS_PROFILE=... infrastructure/scripts/build_and_push.sh ~/master.zip

set -eu

if [ -z "${PROJECT_NAME+x}" ]
then
      export PROJECT_NAME="aws-hands-on-ci-cd"
fi

if [ -z "${RELEASE_BUCKET+x}" ]
then
      export RELEASE_BUCKET="aws-hands-on-ci-cd-release-bucket"
fi

if [ -z "${S3_KEY+x}" ]
then
      export S3_KEY="aws-hands-on-ci-cd/master.zip"
fi

ARTIFACTS_DIR="/tmp/$PROJECT_NAME/build"

if [ -z "${FILE+x}" ]
then
  export FILE="$ARTIFACTS_DIR/master.zip"
else
    if [ -f "$FILE" ]
    then
      echo "$FILE found."
    else
      echo "$FILE not found. Falling back to default value..."
      export FILE="$ARTIFACTS_DIR/master.zip"
    fi
fi

echo "> Running build zip..."

cd "$(dirname "$0")"

(
  cd ../../

  echo "> Zipping project"
  rm -f $ARTIFACTS_DIR/master.zip && zip -r $ARTIFACTS_DIR/master.zip . -x "*/.terraform*" "*.git*" "*.idea*"

  echo "> Done with building zip"
)

echo "> Running push to S3..."

(
  echo "> Pushing file ${FILE} to S3 ${RELEASE_BUCKET}/${S3_KEY}..."

  aws s3 cp $FILE s3://${RELEASE_BUCKET}/${S3_KEY}

  echo "> Done with S3 push"
)

echo "> Done"
