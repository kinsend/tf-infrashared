locals {

  tags = merge(local.default_tags,
    {
      "${var.brand_prefix}:environment"          = "infrashared"
      "${var.brand_prefix}:access"               = "restricted"
      "${var.brand_prefix}:risk"                 = "medium"
      "${var.brand_prefix}:classification"       = "private"
  })

  tags_linux = merge(local.default_tags, local.tags,
    {
      "${var.brand_prefix}:os" = "linux"
  })

}

variable "module_name" {
  type        = string
  description = "The name of this module, derived from the path"
  default     = "base-infra"
}

data "template_file" "user_data_linux" {
  template = file("${path.module}/templates/linux/start-docker-containers.sh.tpl")

  vars = {
    github_token             = jsondecode(data.aws_secretsmanager_secret_version.github_token_version.secret_string)["github/tokens/ks-devops-bot/github-action-runners"]
    brand                    = var.brand
    runner_image             = var.runner_image
    runner_image_version     = var.runner_image_version
    runner_image_dev         = var.runner_image_dev
    runner_image_version_dev = var.runner_image_version_dev
  }
}

data "aws_ami" "ami_linux" {
  most_recent = true
  name_regex  = "^amzn2-ami-hvm-2.*-x86_64-gp2"

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.202*"]
  }

  owners = ["amazon"]
}

data "aws_vpc" "vpc_infrashared" {
  tags = {
    Name = "${var.brand}-infrashared-vpc"
  }
}

# Token for github actions:
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.vpc_infrashared.id
  name   = "default"
}

# Token for github actions:
data "aws_security_group" "infrashared" {
  vpc_id = data.aws_vpc.vpc_infrashared.id
  name = "${var.brand}-infrashared"
}

# This needs to be created manually first and the ARN must be updated here
data "aws_secretsmanager_secret" "github_token" {
  arn = "arn:aws:secretsmanager:${var.aws_region}:202337591493:secret:github/tokens/ks-devops-bot/github-action-runners-9fwIqa"
}

data "aws_secretsmanager_secret_version" "github_token_version" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}
# Token for github actions.
