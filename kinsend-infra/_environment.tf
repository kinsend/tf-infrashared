/*
 * This is a collection of configuration, variables, locals and datasources that
 * are commonly used in all modules. Each module should include a symlink to
 * this file: ln -sf ../_environment.tf
 *
 */
#terraform {
#  backend "s3" {}
#
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 4.0"
#    }
#  }
#}

# Configure provider
provider "aws" {
  #  profile = var.aws_profile
  region = var.aws_region
}

variable "brand" {
  type        = string
  description = "The name of the brand."
  default     = "kinsend"
}

variable "brand_prefix" {
  type        = string
  description = "The abbreviated name of the brand."
  default     = "ks"
}

variable "sub_env" {
  type        = string
  description = "The name of this environment"
  default     = "prod"
}

variable "aws_account_id_infrashared" {
  type        = string
  description = "The ID of the infrashared account."
  default     = "202337591493"
}

variable "aws_account_ids" {
  type        = map(string)
  description = "Map of the various AWS account IDs"
  # Root
  #"202337591493",
  # Dev
  #"065306182146",
  # Prod
  #"113902669333"

  default     = {
    "infrashared" = "202337591493"
    #    "dev"  = "065306182146"
    #    "prod" = "113902669333"
  }
}

variable "aws_profile" {
  type        = string
  description = "AWS profile to use with the AWS provider"
  default     = "kinsend-infra"
}

variable "aws_region" {
  type        = string
  description = "AWS region to configure the AWS provider with"
  default     = "us-east-1"
}

#variable "module_name" {
#  type        = string
#  description = "The name of this module, derived from the path"
#}

variable "environment_name" {
  type        = string
  description = "The name of this environment"
  default     = "prod"
}

variable "terraform_state_bucket" {
  type        = string
  description = "The name of the remote terraform state bucket"
  default     = "kinsend-infra-tf-state"
}

variable "terraform_state_profile" {
  type        = string
  description = "The name of the AWS profile to use for accessing the terraform state bucket"
  default     = "kinsend-infra"
}

variable "terraform_state_region" {
  type        = string
  description = "The AWS region where the terraform state bucket exists"
  default     = "us-east-1"
}

variable "create_cloudwatch_log_group" {
  description = "creates log group for rds in cloudwatch if set to true, defaults to false"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "retention period for rds log group in cloudwatch, defaults to 12 month, specify number of days"
  default     = "365"
}

/*
 * Common locals
 *
 */
locals {
  default_tags = {
    "${var.brand_prefix}:brand"         = "${var.brand}"
    "${var.brand_prefix}:account"       = "infrashared"
    "${var.brand_prefix}:provisionedby" = "terraform"
    "${var.brand_prefix}:service"       = try(regex("[^/]+$", "${path.cwd}"), "no-path")
  }
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}
