terraform {

  backend "s3" {
    bucket = "kinsend-infra-tf-state"
    key = "kinsend-infra/ecr/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
