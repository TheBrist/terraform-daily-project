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
    "roles/iam.workloadIdentityUser" = [
      "principalSet://iam.googleapis.com/projects/${module.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.pool.workload_identity_pool_id}/attribute.repository/TheBrist/Daily-cards-project"
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

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = "cloudrun-access"
  display_name              = "Cloud run access"
  project                   = module.project.id
}

resource "google_iam_workload_identity_pool_provider" "main" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  project                            = module.project.id
  display_name                       = "Github actions"
  description                        = "GitHub Actions identity pool provider for automated test"
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

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem

  is_ca_certificate = true

  subject {
    common_name = module.addresses.external_addresses["elb"].address
    country     = "IL"
    province    = "PT"
    locality    = "PetahTikva"
  }

  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}
