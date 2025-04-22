resource "google_artifact_registry_repository" "my_repo" {
  location      = var.region
  repository_id = "artifact-registry-repo"
  description   = "docker repository"
  format        = "DOCKER"
  project       = module.project.id
}

module "db" {
  source = "./modules/cloudsql-instance"
  project_id = module.project.id
  network_config = {
    connectivity = {
      psa_config = {
        private_network = module.vpc.self_link
      }
    }
  }
  name = "daily-dashboard"
  region = var.region
  database_version = "POSTGRES_13"
  tier = "db-g1-small"
  gcp_deletion_protection = true
  terraform_deletion_protection = false
}

module "cloud_run_back_sa" {
  source     = "./modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudrun-back-sa"

  iam_project_roles = {
    "${module.project.id}" = [
      "roles/cloudsql.client"
    ]
  }
}