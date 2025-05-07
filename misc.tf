module "front_registry" {
  source     = "./modules/artifact-registry"
  project_id = module.project.id
  location   = var.region
  name       = "front-repo"
  format     = { docker = { standard = {} } }
}

module "back_registry" {
  source     = "./modules/artifact-registry"
  project_id = module.project.id
  location   = var.region
  name       = "back-repo"
  format     = { docker = { standard = {} } }
}

module "db" {
  source     = "./modules/cloudsql-instance"
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

  name                          = "daily-dashboard"
  region                        = var.region
  database_version              = "POSTGRES_13"
  tier                          = "db-g1-small"
  gcp_deletion_protection       = true
  terraform_deletion_protection = false
}

module "secret_manager" {
  source = "./modules/secret-manager"
  project_id = module.project.id
  secrets = {
    jwt-secret = {
      locations = [var.region]
    }
  }
  versions = {
    jwt-secret = {
      v1 = {enabled = true, data = random_string.jwt_secret.result}
    }
  }
}

resource "random_string" "jwt_secret" {
  length           = 16
  special          = true
}