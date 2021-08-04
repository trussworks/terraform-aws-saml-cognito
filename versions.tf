terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 3.0"
      configuration_aliases = [aws.us-east-1]
    }
  }
  required_version = ">= 0.13"
}
