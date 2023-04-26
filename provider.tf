# create the ec2 instance
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8.0"
    }
  }
}


# configure the aws provider
provider "aws" {
  region = "ap-south-1"
}
