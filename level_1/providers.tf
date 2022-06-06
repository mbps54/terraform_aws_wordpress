terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "state-locking-bucket"
    key            = "global/level1/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "state-locking-db"
    encrypt        = true
  }
}


provider "aws" {
  region = "eu-central-1"
}
