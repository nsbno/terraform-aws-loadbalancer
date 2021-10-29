terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  version = ">= 3.0"
  region  = var.region
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

module "lb" {
  source      = "../../"
  name_prefix = var.name_prefix
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids
  type        = "application"

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}
