module "vpc" {
  source     = "./modules/net-vpc"
  project_id = module.project.id
  name       = "mynetwork"

  subnets = [for subnet in var.subnets : {
    ip_cidr_range = subnet.ip_cidr_range
    name          = subnet.name
    region        = var.region
  }]

  psa_configs = [{
    ranges          = { cloud-sql = var.cloud_sql_cidr_range }
    deletion_policy = "ABANDON"
  }]

  subnets_proxy_only = [
    {
      ip_cidr_range = var.elb_cidr_range
      name          = "subnet-exl"
      region        = var.region
    },
  ]
}

module "firewall" {
  source     = "./modules/net-vpc-firewall"
  project_id = module.project.id
  network    = module.vpc.name

  ingress_rules = {
    allow-cloudrun-to-sql = {
      description        = "Allow backend cloudrun service to access sql database"
      source_ranges      = [module.vpc.subnets["${var.region}/backend-cloudrun"].ip_cidr_range]
      destination_ranges = [module.db.ip]
      rules              = [{ protocol = "tcp", ports = [5432] }]
    }
  }
}

module "addresses" {
  source     = "./modules/net-address"
  project_id = module.project.id
  external_addresses = {
    "github-runner" = {
      region = var.region
    }
  }
  global_addresses = {
    "elb" = {
    },
  }
}

module "external-lb" {
  source     = "./modules/net-lb-app-ext"
  project_id = module.project.id
  name       = "external-lb"
  forwarding_rules_config = {
    "" = {
      address = (
        module.addresses.global_addresses["elb"].address
      )
    }
  }
  backend_service_configs = {
    frontend = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks        = []
      health_check_configs = {}
      port_name            = "http"
      iap_config = {
        oauth2_client_id     = data.google_secret_manager_secret_version.iap_client_id.secret_data
        oauth2_client_secret = data.google_secret_manager_secret_version.iap_client_secret.secret_data
      }
    }
    backend = {
      backends = [
        { backend = "neg-1" }
      ]
      health_checks        = []
      health_check_configs = {}
      port_name            = "http"
      iap_config = {
        oauth2_client_id     = data.google_secret_manager_secret_version.iap_client_id.secret_data
        oauth2_client_secret = data.google_secret_manager_secret_version.iap_client_secret.secret_data
      }
    }
  }

  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.frontend_cloud_run.service_name
        }
      }
    }
    neg-1 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.backend_cloud_run.service_name
        }
      }
    }
  }

  health_check_configs = {}

  urlmap_config = {
    default_service = "frontend"
    path_matchers = {
      main = {
        default_service = "frontend"
        path_rules = [
          {
            paths = [
              "/api", "/api/*"
            ]
            service = "backend"
          }
        ]
      }
    }
    host_rules = [
      {
        hosts        = ["*"]
        path_matcher = "main"
      }
    ]
  }

  protocol = "HTTPS"
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = ["ronyaskin.ondutyschedulers.com"]
      }
    }
  }
}

resource "google_compute_region_security_policy" "israel_only_policy" {
  name        = "allow-only-israel"
  description = "Allow requests only from Israel"
  project     = module.project.id
  type        = "CLOUD_ARMOR"

  rules {
    action   = "allow"
    priority = 1000
    match {
      expr {
        expression = "origin.region_code=='IL'"
      }
    }
    description = "Allow only requests from Israel"
  }

  rules {
    action   = "deny(403)"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic (default rule)"
  }
}

data "google_secret_manager_secret_version" "iap_client_id" {
  secret  = "iap-client-id"
  project = module.project.id
  version = 2
}

data "google_secret_manager_secret_version" "iap_client_secret" {
  secret  = "iap-client-secret"
  project = module.project.id
  version = 2
}
