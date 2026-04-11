terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Primary region — us-east-1 (active)
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# DR region — us-west-2 (warm standby)
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# CloudFront WAF must always be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
