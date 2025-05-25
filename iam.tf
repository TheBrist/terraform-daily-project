module "github_sa" {
  source       = "./modules/iam-service-account"
  project_id   = module.project.id
  name         = "gh-runner"
  display_name = "Github Runner Service Account"

  iam_project_roles = {
    "${module.project.id}" = [
      "roles/owner",
      "roles/appengine.appAdmin",
      "roles/run.admin"
    ]
  }

  iam = {
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${module.github_sa.email}",
      "serviceAccount:${module.project.number}-compute@developer.gserviceaccount.com"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "principalSet://iam.googleapis.com/projects/${module.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gh.workload_identity_pool_id}/attribute.repository/TheBrist/Daily-cards-project",
      "principalSet://iam.googleapis.com/projects/${module.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.tf.workload_identity_pool_id}/attribute.repository/TheBrist/terraform-daily-project"
    ]

  }
}

module "cloudsql_sa" {
  source     = "./modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudsql-sa"

  iam_project_roles = {
    "${module.project.id}" = [
      "roles/storage.admin"
    ]
  }
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

resource "google_iam_workload_identity_pool" "gh" {
  workload_identity_pool_id = "cloudrun"
  display_name              = "Cloud run access"
  project                   = module.project.id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [display_name]
  }
}


resource "google_iam_workload_identity_pool" "tf" {
  workload_identity_pool_id = "tfpool"
  display_name              = "Terraform access"
  project                   = module.project.id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [display_name]
  }
}

resource "google_iam_workload_identity_pool_provider" "gh" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gh.workload_identity_pool_id
  workload_identity_pool_provider_id = "ghpool"
  project                            = module.project.id
  display_name                       = "Github Actions"
  description                        = "GitHub Actions identity pool provider for automated test."
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "attribute.repository == 'TheBrist/Daily-cards-project'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "tf" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.tf.workload_identity_pool_id
  workload_identity_pool_provider_id = "tfpool"
  project                            = module.project.id
  display_name                       = "TERRAFORM"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "attribute.repository == 'TheBrist/terraform-daily-project'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# resource "google_organization_policy" "enable_lb_policy" {
#   org_id = var.org_id
#   constraint = "compute.restrictLoadBalancerCreationForTypes"

#   list_policy {
#     allow {
#       all = true
#     }
#   }
# }

# resource "google_organization_policy" "enabl_wif_policy" {
#   org_id = var.org_id
#   constraint = "iam.workloadIdentityPoolProviders"

#    list_policy {
#     allow {
#       all = true
#     }
#   }
# }