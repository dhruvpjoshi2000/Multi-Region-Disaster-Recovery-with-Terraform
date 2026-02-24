# ------------------------------------------------------------------------------
# 1. PRIMARY REGION RESOURCES (Active)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "primary" {
  provider = aws.primary # Explicitly using primary provider
  bucket   = "my-app-primary-data-${var.primary_region}"
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# 2. SECONDARY REGION RESOURCES (Passive / DR)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "dr" {
  provider = aws.dr # Explicitly using DR provider
  bucket   = "my-app-dr-data-${var.dr_region}"
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# 3. CROSS-REGION REPLICATION (CRR) CONFIGURATION
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  # Must point to the source bucket
  bucket   = aws_s3_bucket.primary.id 
  role     = aws_iam_role.replication.arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }
  }
}

# ------------------------------------------------------------------------------
# 4. GLOBAL TRAFFIC MANAGEMENT (Route 53)
# ------------------------------------------------------------------------------

# Fetch the existing Hosted Zone
data "aws_route53_zone" "main" {
  provider = aws.primary
  name     = var.domain_name
}

# Health Check: Monitors the Primary Region
resource "aws_route53_health_check" "primary" {
  provider          = aws.primary
  fqdn              = "app.${var.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
  
  tags = {
    Name = "primary-region-health-check"
  }
}

# Primary DNS Record (Active)
resource "aws_route53_record" "primary" {
  provider = aws.primary
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = "app.${var.domain_name}"
  type     = "A"
  
  # Failover Policy: PRIMARY
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier = "primary"
  health_check_id = aws_route53_health_check.primary.id

  # In a real scenario, this points to your ALB or Elastic IP
  ttl     = 60
  records = ["1.1.1.1"] 
}

# Secondary DNS Record (Passive)
resource "aws_route53_record" "secondary" {
  provider = aws.primary
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = "app.${var.domain_name}"
  type     = "A"

  # Failover Policy: SECONDARY
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary"
  
  # In a real scenario, this points to your DR ALB or S3 Website
  ttl     = 60
  records = ["2.2.2.2"] 
}
