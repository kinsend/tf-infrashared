#module "aws_s3_bucket" {
#  source                  = "terraform-aws-modules/s3-bucket/aws"
#  version                 = "3.8.2"
#  bucket                  = "github-action-runners"
#  acl                     = "private"
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#  versioning = {
#    enabled = true
#  }
#  tags = local.tags
#}
