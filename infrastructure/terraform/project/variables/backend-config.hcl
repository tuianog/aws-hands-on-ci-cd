# Create a new file based on this one if a new project is to be deployed
# Update the pipeline module variable to match the file path
region         = "eu-west-1"
bucket         = "terraform-state-916839795767-eu-west-1"
dynamodb_table = "terraform-state-916839795767-eu-west-1"
key            = "aws-hands-on-ci-cd/project/terraform.tfstate"