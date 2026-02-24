# Multi-Region Disaster Recovery (DR) with Terraform

This project provisions a **Multi-Region Active-Passive** infrastructure on AWS using Terraform. It ensures business continuity by automatically failing over traffic from a Primary Region (Active) to a Secondary Region (Passive) in the event of a regional outage.

## 🏗 Architecture

The architecture relies on three core components:
1.  **Storage:** S3 Buckets with Cross-Region Replication (CRR) to keep data synchronized.
2.  **Networking:** Provider aliases to manage resources in `us-east-1` (Primary) and `us-west-2` (DR) simultaneously.
3.  **Traffic Management:** Route 53 DNS Failover with Health Checks to detect outages and reroute traffic.

![Architecture Diagram]


### Traffic Flow
1.  **Normal Operation:** Route 53 checks the health of the Primary Region. If healthy, 100% of traffic goes to Primary.
2.  **Data Sync:** Any data written to the Primary S3 bucket is asynchronously replicated to the DR bucket.
3.  **Failover Event:** If the Primary Region endpoint becomes unreachable, Route 53 detects the failure and updates DNS records to point to the Secondary Region.

---

## 📂 Project Structure

```text
.
├── main.tf        # Core resources (S3, Route53, Health Checks)
├── providers.tf   # AWS Provider configurations with Aliases (us-east-1 & us-west-2)
├── variables.tf   # Configuration variables (Regions, Domain Name)
├── iam.tf         # IAM Roles and Policies for S3 Replication
└── README.md      # This documentation

🚀 Prerequisites
Terraform v1.0+ installed locally.

AWS CLI installed and configured with appropriate credentials.

A Registered Domain Name in AWS Route 53 (e.g., example.com).

🛠 Deployment Guide
1. Initialize the Project
Download the AWS provider plugins and initialize the backend.

Bash
terraform init
2. Configure Variables
Create a terraform.tfvars file or pass variables via the command line to specify your domain.

Terraform
# terraform.tfvars
domain_name    = "yourcompany.com"
primary_region = "us-east-1"
dr_region      = "us-west-2"
3. Review the Plan
Check which resources will be created in both regions.

Bash
terraform plan
4. Apply Infrastructure
Provision the resources. Terraform will ask for confirmation.

Bash
terraform apply
🧪 Testing Disaster Recovery
1. Verify Data Replication
To ensure your data is safe during a disaster, we use Cross-Region Replication.

Test Steps:

Log into the AWS Console and go to S3.

Upload a file test.txt to the Primary bucket.

Switch to the Secondary (DR) bucket.

Within moments, test.txt should appear automatically.

2. Simulate Failover
We use Route 53 Failover routing policies to manage traffic.

Test Steps:

In the AWS Console, go to Route 53 > Health Checks.

(Optional) If you are using dummy IPs (1.1.1.1), the health check may already be failing or passing depending on the target. To simulate a crash, you can manually Invert Health Check Status in the Health Check settings to force it to report "Unhealthy".

Open your terminal and query the DNS:

Bash
dig app.yourcompany.com +short
Result: You should see the IP address associated with the Secondary Region.

🧹 Cleanup
To avoid ongoing charges for the S3 buckets and Route 53 hosted zones, destroy the infrastructure when finished.

Note: Terraform cannot destroy S3 buckets that contain objects. You must empty both buckets manually in the AWS Console before running this command.

Bash
terraform destroy
