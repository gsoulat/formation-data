terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta3"
    }
  }
}

provider "aws" {
  # Configuration options
  region     = var.region
  access_key = "" # TODO
  secret_key = "" # TODO
}
