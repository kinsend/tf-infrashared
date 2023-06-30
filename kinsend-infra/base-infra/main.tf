terraform {

  backend "s3" {
    bucket = "kinsend-infra-tf-state"
    key = "kinsend-infra/base-infra/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.6"
    }
  }
}
