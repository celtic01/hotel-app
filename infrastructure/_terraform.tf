terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.4, <=3.32"
    }
  }
    required_version = ">= 0.12"

}