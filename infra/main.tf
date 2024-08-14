# terraform import aws_route53_zone.hosted_zone HOSTED_ZONE_ID

variable "domain" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "infra.${TF_VAR_domain}"
    key    = "terraform.tfstate"
    region = var.region
  }
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

resource "aws_route53_zone" "hosted_zone" {
  name = var.domain

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_s3_bucket" "lambda_bucket" {
  bucket = "infra.${var.domain}"
}