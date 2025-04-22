terraform {
  backend "gcs" {
    bucket = "tfstate-daily-project"
  }
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.20.0"
    }
  }
}

provider "google" {
  region = var.region
  impersonate_service_account = "terraform-sa@daily-cards-hafifa-project.iam.gserviceaccount.com"
}