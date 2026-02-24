variable "primary_region" {
  description = "The primary active region"
  default     = "us-east-1"
}

variable "dr_region" {
  description = "The secondary disaster recovery region"
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Your domain name for Route53 (must exist)"
  type        = string
  default     = "example.com"
}
