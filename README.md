# AWS-Hands-On-CI-CD

Test project. Serves as a practical hands on implementation. 

___

## Infrastructure

Contains all the code related with the infrastructure. That mainly includes bash scripts for automation and terraform code to represent all the infrastructure resources needed.

There are two current environments:

* **Pipeline**: the infrastructure code for creating the CodePipeline and all necessary resources for deployment of the project. Needs to be run manually;
* **Project**: the infrastructure code of the project itself to be deployed by the pipeline.

___

## Project

### Backend

The backend used for this purpose is a simple Python lambda that performs CRUD operations on a DynamoDB table. An API Gateway is used to expose a REST API.

___

## Deployment

Both the project and the pipeline are deployed on the same account.

Example of pipeline deployment (requires to previously have valid credentials on the account to be deployed):

    AWS_PROFILE=... terraform apply

The project can also be deployed directly from the host machine the same way the pipeline is. Though, only the pipeline should be used for deploying the project. 

The pipeline is triggered when an S3 object is pushed to the release bucket. For this project we do not have a webhook configured. Thus, we have scripts to package the project in a zip file and push it to the release bucket.

Example of running the script to build and push to S3:

    AWS_PROFILE=... infrastructure/scripts/build_and_push.sh

___

## Webhook

Custom webhook implemented based on an API Gateway and a Lambda in Python. It's a middleware between BitBucket and AWS CodePipeline. Its purpose is to zip git branches and store them on an S3 bucket which is the source of the deployment pipeline.

Thus, each push to the repository triggers the webhook which adds an S3 object to the release bucket - a zip file with the branch name.

Pre-requirements:
* Generate a pair of SSH keys for the webhook
* Add the private key to the Secrets Manager (use the terraform 'secret' module)
* Change the repository permissions - add the public key to the access list (read permissions)



