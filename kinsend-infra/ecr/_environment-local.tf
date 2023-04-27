locals {

  tags = merge(local.default_tags,
    {
      "${var.brand_prefix}:environment"          = "infrashared"
      "${var.brand_prefix}:access"               = "restricted"
      "${var.brand_prefix}:risk"                 = "medium"
      "${var.brand_prefix}:classification"       = "private"
    })

}

variable "module_name" {
  type        = string
  description = "The name of this module, derived from the path"
  default     = "ecr"
}
