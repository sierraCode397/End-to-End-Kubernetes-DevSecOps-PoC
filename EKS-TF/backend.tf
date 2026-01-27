terraform {
  backend "s3" {
    bucket = "library-epam-cloud-platform"      /* <---------------- */
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}
