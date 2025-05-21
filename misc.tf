module "front_registry" {
  source     = "./modules/artifact-registry"
  project_id = module.project.id
  location   = var.region
  name       = "front-repo"
  format     = { docker = { standard = {} } }
  cleanup_policy_dry_run = false
  cleanup_policies = {
    keep-5-versions = {
      action = "KEEP"
      most_recent_versions = {
        keep_count            = 5
      }
    }
    keep-tagged-release = {
      action = "KEEP"
      condition = {
        tag_state             = "TAGGED"
        tag_prefixes          = ["release"]
      }
    }
  }
}

module "back_registry" {
  source     = "./modules/artifact-registry"
  project_id = module.project.id
  location   = var.region
  name       = "back-repo"
  format     = { docker = { standard = {} } }
  cleanup_policy_dry_run = false
  cleanup_policies = {
    keep-5-versions = {
      action = "KEEP"
      most_recent_versions = {
        keep_count            = 5
      }
    }
    keep-tagged-release = {
      action = "KEEP"
      condition = {
        tag_state             = "TAGGED"
        tag_prefixes          = ["release"]
      }
    }
  }
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

  name                          = var.db_name
  region                        = var.region
  database_version              = "POSTGRES_13"
  tier                          = "db-g1-small"
  gcp_deletion_protection       = true
  terraform_deletion_protection = false
}

module "secret_manager" {
  source     = "./modules/secret-manager"
  project_id = module.project.id
  secrets = {
    jwt-secret = {
      locations = [var.region]
    }
    db-password = {
      locations = [var.region]
    }
  }
  versions = {
    jwt-secret = {
      v1 = { enabled = true, data = random_string.jwt_secret.result }
    }
    db-password = {
      v1 = { enabled = true, data = var.db_password }
    }
  }
}

resource "random_string" "jwt_secret" {
  length  = 16
  special = true
}
