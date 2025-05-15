terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  version = ">= 3.0"
  region  = var.region
}

data "aws_vpc" "main" {
  tags = {
	Name = "shared"
  }
}

data "aws_subnets" "public" {
  filter {
	name   = "vpc-id"
	values = [data.aws_vpc.main.id]
  }

  tags = {
	Tier = "Public"
  }
}

module "lb_certificate" {
  source           = "github.com/nsbno/terraform-aws-acm-certificate?ref=x.y.z"
  hosted_zone_name = "test.infrademo.vydev.io"
  domain_name      = "alb.test.infrademo.vydev.io"
}

module "lb" {
  source      = "../../"

  type        = "application"
  name_prefix = "basic-example"

  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnets.public.ids

  certificate_arns = [module.lb_certificate.arn]
}
