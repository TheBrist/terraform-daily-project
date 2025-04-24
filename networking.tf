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
      source_ranges      = [module.vpc.subnets["${var.region}/cr-back-vpc-connector"].ip_cidr_range]
      destination_ranges = [module.db.ip]
      rules              = [{ protocol = "tcp", ports = [5432] }]
    }
  }
}

module "addresses" {
  source     = "./modules/net-address"
  project_id = module.project.id
  external_addresses = {
    "elb" = {
      region = var.region
      tier   = "STANDARD"
    }
  }
}

module "external-lb" {
  source     = "./modules/net-lb-app-ext-regional"
  project_id = module.project.id
  name       = "external-lb"
  vpc        = module.vpc.self_link
  region     = var.region
  address    = module.addresses.external_addresses["elb"].id
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
    }
  }

  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.frontend_cloud_run.service_name
        }
      }
    }
  }

  ssl_certificates = {
    create_configs = {
      external-lba = {
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
  } }
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
