terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket                  = "weatherapp-tfstate"
    key                     = "weatherapp"
    region                  = "us-east-1"
  }

  required_version = ">= 1.8.0"
}

provider "aws" {
  region = "us-east-1"
}
