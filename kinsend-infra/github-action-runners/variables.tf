variable "runner_image" {
  default     = "202337591493.dkr.ecr.us-east-1.amazonaws.com/github-action-runners"
  type        = string
  description = "runner image location"
}

variable "runner_image_dev" {
  default     = "202337591493.dkr.ecr.us-east-1.amazonaws.com/github-action-runners"
  type        = string
  description = "runner image location"
}

variable "runner_image_version" {
  default     = "1.0.2"
  type        = string
  description = "runner image version"
}

variable "runner_image_version_dev" {
  default     = "1.0.2"
  type        = string
  description = "runner image version"
}

variable "name" {
  default     = "github-action-runners"
  type        = string
  description = "name/prefix to use for all resources in this module"
}

variable "name_linux" {
  default     = "github-action-runner-linux"
  type        = string
  description = "name/prefix to use for the Linux Github Action Runners"
}

variable "name_windows" {
  default     = "github-action-runner-windows"
  type        = string
  description = "name/prefix to use for the Windows Github Action Runners"
}

variable "env" {
  default     = "infrashared"
  type        = string
  description = "environment"
}

variable "instance_type_linux" {
  description = "The type of EC2 instance to provision for the Linux-based Github Action Runners"
  # default     = "t2.small"
  default     = "t2.large"
}

variable "instance_type_windows" {
  description = "The type of EC2 instance to provision for the Windows-based Github Action Runners"
  default     = "m6a.large"
}
