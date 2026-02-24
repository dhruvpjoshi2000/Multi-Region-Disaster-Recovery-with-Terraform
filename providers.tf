terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The Default Provider (Primary Region)
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# The Secondary Provider (DR Region)
provider "aws" {
  region = var.dr_region
  alias  = "dr"
}
