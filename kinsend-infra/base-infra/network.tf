locals {
  tg_tags = {
    "${var.brand_prefix}:environment"    = var.sub_env
    "${var.brand_prefix}:provisionedby"  = "terraform"
    "${var.brand_prefix}:access"         = "restricted"
    "${var.brand_prefix}:risk"           = "medium"
    "${var.brand_prefix}:classification" = "private"
    "${var.brand_prefix}:brand"         = "${var.brand}"
  }
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block                           = "10.0.0.0/16"
  enable_dns_support                   = true
  enable_dns_hostnames                 = true
  enable_network_address_usage_metrics = true
  tags                                 = merge(local.default_tags, { "Name" = "${var.brand}-infrashared-vpc" })
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.default_tags
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = merge(local.default_tags, { "Name" = "${var.brand}-infrashared-subnet" })
}

# Create route table
resource "aws_route_table" "public" {
  tags   = local.default_tags
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate public subnet with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
  #  tags           = local.default_tags
}

# Create security group
resource "aws_security_group" "sg_infrashared" {
  name   = "${var.brand}-infrashared"
  vpc_id = aws_vpc.vpc.id
  tags   = local.default_tags

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      # ldn.carlspring.org
      "80.229.251.196/32",
      # sof.carlspring.org
      "85.196.153.20/32",
      # Pleven
      "212.233.214.112/32"
    ]
    #    from_port = 0
    #    to_port = 0
    #    protocol = "-1"
    #    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
