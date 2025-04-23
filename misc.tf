resource "google_artifact_registry_repository" "front" {
  location      = var.region
  repository_id = "front-repo"
  description   = "docker repository"
  format        = "DOCKER"
  project       = module.project.id
}

resource "google_artifact_registry_repository" "back" {
  location      = var.region
  repository_id = "back-repo"
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

  flags = {
    "cloudsql.iam_authentication" = "on"
  }

  users = {
    (module.cloudsql_sa.email) = {
      type = "CLOUD_IAM_SERVICE_ACCOUNT"
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

module "github_sa" {
  source     = "./modules/iam-service-account"
  project_id = module.project.id
  name       = "github-sa"

  iam_project_roles = {
    "${module.project.id}" = [
      "roles/artifactregistry.repoAdmin",
      "roles/run.admin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/storage.admin",
      "roles/iam.serviceAccountUser",
    ]
  }
}

module "cloudsql_sa" {
  source = "./modules/iam-service-account"
  project_id = module.project.id
  name = "cloudsql-sa"

  iam_project_roles = {
    "${module.project.id}" = [
      "roles/storage.admin"
    ]
  }
}