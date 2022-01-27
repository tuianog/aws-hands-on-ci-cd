#!/bin/bash

set -euo pipefail

TERRAFORM_VERSION=0.12.28

echo "> Installing terraform version ${TERRAFORM_VERSION}..."

wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform /usr/local/bin

echo "> Checking terraform version"
terraform --version