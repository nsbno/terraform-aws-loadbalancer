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
# NOTE: You will have apply twice (or create the bucket first) due to a AWS provider issue.
# This has to do with the aws_s3_bucket and not the module. See e2e tests for more details.
resource "aws_s3_bucket" "this" {
  bucket = "lb-example"
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json
}

# Ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html
# (ALB: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions)
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bucket" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this.arn]
  }
}

module "lb_certificate" {
  source           = "github.com/nsbno/terraform-aws-acm-certificate?ref=x.y.z"
  hosted_zone_name = "test.infrademo.vydev.io"
  domain_name      = "nlb.test.infrademo.vydev.io"
}

module "lb" {
  source = "../../"

  name_prefix = "lb-example"
  type        = "network"

  vpc_id     = data.aws_vpc.main.id
  subnet_ids = data.aws_subnets.public.ids

  access_logs = {
    bucket  = aws_s3_bucket.this.id
    enabled = true
  }

  certificate_arns = [module.lb_certificate.arn]
}
