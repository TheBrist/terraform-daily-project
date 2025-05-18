billing_account_id                = "01A98A-A178F7-4BC158"
project_name                      = "daily-cards-hafifa-project"
terraform_service_account_address = "terraform-sa@daily-cards-hafifa-project.iam.gserviceaccount.com"
project_apis = [
  "iamcredentials.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "serviceusage.googleapis.com",
  "sqladmin.googleapis.com",
  "servicenetworking.googleapis.com",
  "iam.googleapis.com",
  "vpcaccess.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "secretmanager.googleapis.com",
  "run.googleapis.com",
  "dns.googleapis.com",
  "secretmanager.googleapis.com",
  "domains.googleapis.com",
  "iap.googleapis.com",
  "certificatemanager.googleapis.com",
]
cloud_run_back_name  = "backend-daily-cards"
cloud_run_front_name = "frontend-daily-cards"
subnets = [
  {
    ip_cidr_range = "10.10.10.0/26"
    name          = "backend-cloudrun"
  },
  {
    ip_cidr_range = "10.11.10.0/24"
    name = "vm"
  }
]
cloud_sql_cidr_range = "10.60.0.0/16"
elb_cidr_range       = "10.20.0.0/24"
db_name = "daily-dashboard"
database = "postgres"
db_password = "postgres"
db_user = "postgres"