terraform {

  backend "s3" {
    bucket = "kinsend-infra-tf-state"
    key = "kinsend-infra/github-action-runners/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// This role is assigned to the EC2 instance and allows it to automatically gain access to the resources it needs.
// The managed_policy_arns are additional policies which are also applied to the role.
resource "aws_iam_role" "ghar_admin" {
  name = "${var.brand}-${var.name}-admin"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    // Allow EC2 Admin access
    data.aws_iam_policy.AmazonEC2FullAccess.arn,
    // SSM access
    data.aws_iam_policy.AmazonSSMFullAccess.arn,
    // VPC read-only access
    data.aws_iam_policy.AmazonVPCReadOnlyAccess.arn,
    // Allow access to terraform state.
    aws_iam_policy.terraform_state_access.arn,
    // Allow ECR access
    aws_iam_policy.ecr-access.arn,
    // Aggregated policy (Policy limit is 10)
    aws_iam_policy.action_runner_aggregated_policies.arn
  ]
}

resource "aws_iam_policy" "action_runner_aggregated_policies" {
  name   = "${var.brand}-${var.name}-aggregated-policies"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // allow_action_runner_to_manage_policies
      {
        // Overall management access to self assigned profiles
        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:ListInstanceProfilesForRole",
          "iam:GetInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListInstanceProfileTags",
          "iam:ListInstanceProfiles",
          "iam:UntagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:TagInstanceProfile"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${var.aws_account_id_infrashared}:instance-profile/${var.brand}-${var.name}-*"
        ]
      },
      // /allow_action_runner_to_manage_policies

      // allow_action_runner_to_manage_roles
      {
        // Overall read access to all roles
        Action = [
          "iam:ListRoleTags",
          "iam:ListInstanceProfilesForRole",
          "iam:GetServiceLinkedRoleDeletionStatus",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRolePolicy",
        ]
        Effect   = "Allow"
        Resource = [ "*" ]
      },
      {
        // Fine-grained write access
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UntagRole",
          "iam:TagRole",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:UpdateRoleDescription",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeletePolicy",
          "iam:PutRolePolicy",
          "iam:PutGroupPolicy",
          "iam:PutRolePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${var.aws_account_id_infrashared}:role/${var.brand}-${var.name}-*",
          "arn:aws:iam::${var.aws_account_id_infrashared}:policy/${var.brand}-${var.name}-*",
          "arn:aws:iam::aws:policy/Amazon*" // aws managed policies.
        ]
      },
      // /allow_action_runner_to_manage_roles

      // allow_action_runner_to_manage_launch_configurations
      {
        Action = [
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DescribeLaunchConfigurations"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${var.aws_account_id_infrashared}:instance-profile/${var.brand}-${var.name}-*",
          "arn:aws:iam::${var.aws_account_id_infrashared}:policy/${var.brand}-${var.name}-*"
        ]
      },
      // /allow_action_runner_to_manage_launch_configurations

      // allow_secrets_access
      {
        Action    = [ "secretsmanager:DescribeSecret", "secretsmanager:List*", "secretsmanager:Get*" ]
        Effect    = "Allow"
        Resource  = [ "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id_infrashared}:*" ]
      },
      // /allow_secrets_access

      // allow_decode_authorization_message
      {
        Action    = [ "sts:DecodeAuthorizationMessage" ]
        Effect    = "Allow"
        Resource  = [ "*" ]
      }
      // /allow_decode_authorization_message

    ]
  })
}

resource "aws_iam_policy" "terraform_state_access" {
  name   = "${var.brand}-${var.name}-terraform-state-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "1"
        Action    = [ "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem" ]
        Effect    = "Allow"
        Resource  = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id_infrashared}:table/terraform-state-lock"
        ]
      },
      {
        Sid       = "2"
        Action    = [ "s3:ListBucket", "s3:GetObject", "s3:PutObject" ]
        Effect    = "Allow"
        Resource  = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ecr-access" {
  name   = "${var.brand}-${var.name}-ecr-access"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = [ "ecr:CreateRepository", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage" ]
        Effect    = "Allow"
        Resource  = [
          "arn:aws:ecr:${var.aws_region}:${var.aws_account_id_infrashared}:repository/github-action-runners"
        ]
      },
      {
        Action    = [ "ecr:GetAuthorizationToken" ]
        Effect    = "Allow"
        Resource  = ["*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ghar" {
  # Keeping the profile name the same as the role name.
  name = aws_iam_role.ghar_admin.name
  role = aws_iam_role.ghar_admin.name
}

data "aws_iam_policy" "AmazonSSMFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "AmazonVPCReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess"
}

data "aws_iam_policy" "AmazonEC2FullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "A service linked role for autoscaling"
  custom_suffix    = var.name

  # Sometimes good sleep is required to have some IAM resources created before they can be used
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

data "aws_subnet" "infrashared" {
  filter {
    name   = "tag:Name"
    values = [ "${var.brand}-infrashared-subnet" ]
  }
}

resource "aws_key_pair" "ssh_access_key" {
  key_name   = "${var.brand}-infrashared-ssh-rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1oDr7DHROHeui3N5Ufa921RN3heEA71lJggHvBYYb/Fbig4B3hyCxUtF47RfIu/ofZfYA/FdCNoqqkg4X19oM3J5VoWt95f4LtHoImKTYVfE3SD2AauZOqbDRz7tOiqyek9WEihX8ZgFTdMnJLvaIvKaNOKYWOG4LCnhIOOWJ4XhlApWFXcz1+kRh4NlLex1xoditwjR1euU4XbPCToDztzaVC/3kum+RYeruElpWVGpFbWN8W0E4qr1fM5zpISovbSo3FiuM2lVieAEP5Y8A0olmbrC4lPew9NCpn8GpNE2BgCAAen3SNQhJbj0EKBzcRrqaaMYMdJK044CScy2kyLOA0hEkxwN7MqmuYTxIelayOQKWKQSdVIR22PJwsWnFexOZCo07H/3GhPqA4ay/yn9d+2NF62M+hCI+dIaE/N7HNW/AoAEZDlitfJp9B9JzFyiFQjGmZFjYWeFPYDeo6yLdZk0GqrOwwtW0cSbkVZAAnxLkzetZMindmksdHmU= ks-dev@kinsend.io"
}

module "runners_linux" {
  source                = "terraform-aws-modules/autoscaling/aws"
  version               = "~> 6.9"
  name                  = var.name_linux
  image_id              = data.aws_ami.ami_linux.id
  instance_type         = var.instance_type_linux
  security_groups       = [data.aws_security_group.default.id, data.aws_security_group.infrashared.id]
  key_name              = aws_key_pair.ssh_access_key.key_name

  # recreate_asg_when_lc_changes = true
  # above option does not exist, you will need to terminate running instances to take effect
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs         = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 10
        volume_type           = "gp3"
      }
    }
  ]

  vpc_zone_identifier = [ data.aws_subnet.infrashared.id ]

  health_check_type         = "EC2"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 3
  wait_for_capacity_timeout = 0
  service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn
  iam_instance_profile_arn  = aws_iam_instance_profile.ghar.arn
  user_data                 = base64encode(data.template_file.user_data_linux.rendered)
  tags                      = local.tags_linux

  # Required to avoid "ValidationError: ARN specified for Service-Linked Role does not exist."
  depends_on = [
    aws_iam_service_linked_role.autoscaling
  ]

  schedules = {
    earlymorning = {
      desired_capacity = 1
      min_size         = 1
      max_size         = 1
      recurrence       = "0 3 * * 1-7" # 3am Mon-Sun when little use
      time_zone        = "Europe/London"
    }

    morning = {
      desired_capacity = 1
      min_size         = 1
      max_size         = 3
      recurrence       = "0 7 * * 1-7" # Mon-Sun in the morn, back to normal
      time_zone        = "Europe/London"
    }
  }

  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      disable_scale_in              = true
      policy_type                   = "TargetTrackingScaling"
      estimated_instance_warmup     = 900
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
  }

}
