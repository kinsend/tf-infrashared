resource "aws_ecr_repository" "github_action_runners" {
  name                 = "github-action-runners"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags

#  lifecycle {
#    prevent_destroy = true
#  }
}
