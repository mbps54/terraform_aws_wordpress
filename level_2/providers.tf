terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "state-locking-bucket"
    key            = "global/level2/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "state-locking-db"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}


data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket = "state-locking-bucket"
    key    = "global/level1/terraform.tfstate"
    region = "eu-central-1"
  }
}
